//
//  CommonLocationManager.swift
//  anpg-radar
//
//  Created by Esben von Buchwald on 13/04/2017.
//  Copyright © 2017 Esben von Buchwald. All rights reserved.
//

import UIKit
import CoreLocation


enum CommonLocationAccuracy: Int {
    case accurate
    case inaccurate
}

protocol CommonLocationSubscriber: class {
    func updateLocation(location: CLLocation)
    var accuracy: CommonLocationAccuracy {get}
}

class CommonLocationManager: NSObject {

    override init() {
        super.init()
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
        }
    }

    let locationManager = CLLocationManager()

    static let shared = CommonLocationManager()
    
    var inaccurateSubscribers: [CommonLocationSubscriber] = [] {
        didSet {
            update()
        }    }
    
    var accurateSubscribers: [CommonLocationSubscriber] = [] {
        didSet {
            update()
        }
    }

    func update() {
        maxAccuracy = accurateSubscribers.count > 0
        if inaccurateSubscribers.count + accurateSubscribers.count > 0 {
            locationManager.startUpdatingLocation()
        }
        else {
            locationManager.stopUpdatingHeading()
        }
        
        print(locationManager.desiredAccuracy.description)
    }
    
    var maxAccuracy = false {
        didSet {
            locationManager.desiredAccuracy = maxAccuracy ? kCLLocationAccuracyBestForNavigation : kCLLocationAccuracyThreeKilometers
        }
    }
    
    func subscribe(subscriber: CommonLocationSubscriber) {
        print("subscribe: \(subscriber.self)")
        locationManager.stopUpdatingLocation()
        locationManager.startUpdatingLocation()
        switch subscriber.accuracy {
        case .accurate:
            if accurateSubscribers.contains(where: {$0 === subscriber}) {
               return
            }
            accurateSubscribers.append(subscriber)
        case .inaccurate:
            if inaccurateSubscribers.contains(where: {$0 === subscriber}) {
                return
            }
            inaccurateSubscribers.append(subscriber)
        }
        
    }

    func unsubscribe(subscriber: CommonLocationSubscriber) {
        print("unsubscribe: \(subscriber.self)")
        switch subscriber.accuracy {
        case .accurate:
            guard let index = accurateSubscribers.index(where: {$0 === subscriber}) else {return}
            accurateSubscribers.remove(at: index)
        case .inaccurate:
            guard let index = inaccurateSubscribers.index(where: {$0 === subscriber}) else {return}
            inaccurateSubscribers.remove(at: index)
        }
    }
    
    
}

extension CommonLocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // FIXME
        guard let location = manager.location else {return}

        (accurateSubscribers + inaccurateSubscribers).forEach { (subscriber) in
            subscriber.updateLocation(location: location)
        }
        
        print(manager.desiredAccuracy)
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("monitoring failed for ragion with ID \(region?.identifier ?? "N/A")")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("location manager failed with error \(error.localizedDescription)")
    }
    
    
}
