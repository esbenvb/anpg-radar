//
//  CameraAlertManager.swift
//  anpg-radar
//
//  Created by Esben von Buchwald on 06/03/2017.
//  Copyright © 2017 Esben von Buchwald. All rights reserved.
//

import UIKit
import CoreLocation

let kGeofenceLimit = 20 // FIXME

class CameraAlertManager: NSObject {
    let locationManager = CLLocationManager()
    var items: [CameraListItem] {
        didSet {
            estimatedLocation = nil
            previousLocation = nil
            previousDistance = 0
        }
    }
    var currentDistances: [String : CLLocationDistance] = [:]
    var previousLocation: CLLocation?
    var previousDistance: CLLocationDistance = 0
    var estimatedLocation: CLLocation?
    var alertItems: [CameraListItem] = [] {
        didSet {
            stopMonitoringAll()
            alertItems.forEach { startMonitoring(camListItem: $0) }
        }
    }
    
    init(items: [CameraListItem] = []) {
        self.items = items
        super.init()
        
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
//        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.adjustAccuracy()
    }
    
    func updateGeofences() {
        locationManager.stopUpdatingLocation()
        guard let location = estimatedLocation else {return}
        
        currentDistances = [:]
        items.forEach { (item) in
            currentDistances[item.id] = CLLocation(latitude: item.coordinate.latitude, longitude: item.coordinate.longitude).distance(from: location)
        }
        items.sort {
            guard let a = currentDistances[$0.id], let b = currentDistances[$1.id] else {return false}
            return a < b
        }
        
        alertItems = Array(items.prefix(kGeofenceLimit))

        if items.count > kGeofenceLimit, let distance = currentDistances[items[kGeofenceLimit].id] {
            previousDistance = distance
            previousLocation = location
            locationManager.startUpdatingLocation()
        }
    }

    
    func startMonitoring(camListItem: CameraListItem) {
        locationManager.startUpdatingLocation()

        if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            print("NOT SUPPORTED ON DEVICE") // FIXME
            return
        }
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            print ("NEEDS TO GRANT ACCESS") // FIXME
        }
        
        locationManager.startMonitoring(for: camListItem.region)
    }
    
    func stopMonitoringAll() {
        locationManager.monitoredRegions.forEach { locationManager.stopMonitoring(for: $0) }
    }
    
}

extension CameraAlertManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        estimatedLocation = manager.location
        guard let estimatedLocation = estimatedLocation else {return}
        guard let previousLocation = previousLocation, previousDistance > 0 else {
            updateGeofences()
            return
        }
        if estimatedLocation.distance(from: previousLocation) > previousDistance * 0.9 {
            updateGeofences()
        }
        locationManager.adjustAccuracy()
    }
}

extension CLLocationManager {
    func adjustAccuracy() {
        switch UIApplication.shared.applicationState {
        case .active:
            desiredAccuracy = kCLLocationAccuracyBestForNavigation
        case .inactive, .background:
            desiredAccuracy = kCLLocationAccuracyThreeKilometers
        }
    }
}
