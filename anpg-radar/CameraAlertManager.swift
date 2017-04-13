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
    var items: [CameraListItem] {
        didSet {
            estimatedLocation = nil
            previousLocationOfUpdating = nil
            previousDistanceToFirstSkippedItem = 0
        }
    }
    var currentDistances: [String : CLLocationDistance] = [:]
    var previousLocationOfUpdating: CLLocation?
    var previousDistanceToFirstSkippedItem: CLLocationDistance = 0
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

        CommonLocationManager.shared.subscribe(subscriber: self)
    }
    
    func updateGeofences() {
        CommonLocationManager.shared.unsubscribe(subscriber: self)
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
            previousDistanceToFirstSkippedItem = distance
            previousLocationOfUpdating = location
            CommonLocationManager.shared.subscribe(subscriber: self)
        }
    }

    
    func startMonitoring(camListItem: CameraListItem) {
//        CommonLocationManager.shared.subscribe(subscriber: self)

        if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            print("NOT SUPPORTED ON DEVICE") // FIXME
            return
        }
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            print ("NEEDS TO GRANT ACCESS") // FIXME
        }
        
        CLLocationManager().startMonitoring(for: camListItem.region)
    }
    
    func stopMonitoringAll() {
        CLLocationManager().monitoredRegions.forEach { CLLocationManager().stopMonitoring(for: $0) }
    }
    
}

extension CameraAlertManager: CommonLocationSubscriber {
    var isActiveInBackground: Bool {
        return true
    }

    func updateLocation(location: CLLocation) {
        guard let previousLocationOfUpdating = previousLocationOfUpdating, previousDistanceToFirstSkippedItem > 0 else { return }
        // Update if items were skipped and the distance to the last location of update is within 90% of the original distance to the first skipped item.
        if location.distance(from: previousLocationOfUpdating) > previousDistanceToFirstSkippedItem * 0.9 {
            updateGeofences()
        }
    }
    
    var accuracy: CLLocationAccuracy {return kCLLocationAccuracyThreeKilometers}
}
