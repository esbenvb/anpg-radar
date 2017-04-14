//
//  CommonLocationManager.swift
//  anpg-radar
//
//  Created by Esben von Buchwald on 13/04/2017.
//  Copyright © 2017 Esben von Buchwald. All rights reserved.
//

import UIKit
import CoreLocation


class CommonLocationSubscriber: NSObject {
    override init() {
        super.init()
    }
    var updateLocation: ((_ location: CLLocation) -> ())?
    var didEnterRegion: ((_ region: CLRegion) -> ())?
    var didExitRegion: ((_ region: CLRegion) -> ())?
    var accuracy: CLLocationAccuracy = 1000000
    var isLocationActiveInBackground: Bool = false
    
    func enable() {
        CommonLocationManager.shared.subscribe(self)
    }
    
    func disable() {
        CommonLocationManager.shared.unsubscribe(self)
    }
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
            let locationSubscribersExist = subscribers.contains { (subscriber) -> Bool in
                return subscriber.updateLocation != nil
            }
            if locationSubscribersExist {
                locationManager.startUpdatingLocation()
                print("more than 0, starting")
            }
            else {
                locationManager.stopUpdatingLocation()
                print("0, stopping")
            }
            print(locationManager.desiredAccuracy.description)
        }
    }

    func updateAccuracy() {
        var minAccuracy: CLLocationAccuracy = 10000000
        
        let background = UIApplication.shared.applicationState == .background || UIApplication.shared.applicationState == .inactive
        
        subscribers.forEach { subscriber in
            // Skip non backgrounded items if running in background, to make a lower accuracy if possible
            if !background || subscriber.isLocationActiveInBackground {
                minAccuracy = min(subscriber.accuracy, minAccuracy)
            }
        }
        
        locationManager.desiredAccuracy = minAccuracy
    }
    
    func subscribe(_ subscriber: CommonLocationSubscriber) {
        print("subscribe: \(subscriber.self)")
        locationManager.stopUpdatingLocation()
        locationManager.startUpdatingLocation()
        if subscribers.contains(where: {$0 === subscriber}) {
            return
        }
        subscribers.append(subscriber)
        
    }
    
    func unsubscribe(_ subscriber: CommonLocationSubscriber) {
        print("unsubscribe: \(subscriber.self)")
        guard let index = subscribers.index(where: {$0 === subscriber}) else {return}
        subscribers.remove(at: index)
    }
    
    func startMonitoring(for region: CLRegion) {
        if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            print("NOT SUPPORTED ON DEVICE") // FIXME
            return
        }
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            print ("NEEDS TO GRANT ACCESS") // FIXME
        }
        locationManager.startMonitoring(for: region)
    }
    
    func stopMonitoring(for region: CLRegion) {
        locationManager.stopMonitoring(for: region)
    }
    
    func stopMonitoringAll() {
        locationManager.monitoredRegions.forEach { CLLocationManager().stopMonitoring(for: $0) }
    }
}

extension CommonLocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // FIXME
        guard let location = manager.location else {return}

        let background = UIApplication.shared.applicationState == .background || UIApplication.shared.applicationState == .inactive

        subscribers.forEach { (subscriber) in
            // Skip non backgrounded items if running in background
            if !background || subscriber.isLocationActiveInBackground {
                subscriber.updateLocation?(location)
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
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        subscribers.forEach { (subscriber) in
            subscriber.didEnterRegion?(region)
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        subscribers.forEach { (subscriber) in
            subscriber.didExitRegion?(region)
        }
    }
    
}
