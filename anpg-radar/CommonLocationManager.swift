//
//  CommonLocationManager.swift
//  anpg-radar
//
//  Created by Esben von Buchwald on 13/04/2017.
//  Copyright © 2017 Esben von Buchwald. All rights reserved.
//

import UIKit
import CoreLocation


protocol CommonLocationSubscriber: class {
    func updateLocation(location: CLLocation)
    var accuracy: CLLocationAccuracy {get}
    var isActiveInBackground: Bool {get}
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
    
    var subscribers: [CommonLocationSubscriber] = [] {
        didSet {
            updateAccuracy()
            if subscribers.count > 0 {
                locationManager.startUpdatingLocation()
            }
            else {
                locationManager.stopUpdatingLocation()
            }
            print(locationManager.desiredAccuracy.description)
        }
    }

    func updateAccuracy() {
        var minAccuracy: CLLocationAccuracy = 10000000
        
        let background = UIApplication.shared.applicationState == .background || UIApplication.shared.applicationState == .inactive
        
        subscribers.forEach { subscriber in
            // Skip non backgrounded items if running in background, to make a lower accuracy if possible
            if !background || subscriber.isActiveInBackground {
                minAccuracy = min(subscriber.accuracy, minAccuracy)
            }
        }
        
        locationManager.desiredAccuracy = minAccuracy
    }
    
    func subscribe(subscriber: CommonLocationSubscriber) {
        print("subscribe: \(subscriber.self)")
        locationManager.stopUpdatingLocation()
        locationManager.startUpdatingLocation()
        if subscribers.contains(where: {$0 === subscriber}) {
            return
        }
        subscribers.append(subscriber)
        
    }

    func unsubscribe(subscriber: CommonLocationSubscriber) {
        print("unsubscribe: \(subscriber.self)")
            guard let index = subscribers.index(where: {$0 === subscriber}) else {return}
            subscribers.remove(at: index)
    }
}

extension CommonLocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // FIXME
        guard let location = manager.location else {return}

        let background = UIApplication.shared.applicationState == .background || UIApplication.shared.applicationState == .inactive

        subscribers.forEach { (subscriber) in
            // Skip non backgrounded items if running in background
            if !background || subscriber.isActiveInBackground {
                subscriber.updateLocation(location: location)
            }
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
