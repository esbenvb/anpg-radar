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
    
    static let shared: CameraAlertManager = CameraAlertManager()
    
    var items: [CameraListItem] = [] {
        didSet {
            // This will trigger an update when location is received.
            previousLocationOfUpdating = nil
            previousDistanceToFirstSkippedItem = 0
        }
    }
    private var currentDistances: [String : CLLocationDistance] = [:]
    private var previousLocationOfUpdating: CLLocation?
    private var previousDistanceToFirstSkippedItem: CLLocationDistance?
    private var alertItems: [CameraListItem] = [] {
        didSet {
            CommonLocationManager.shared.stopMonitoringAll()
            alertItems.forEach { startMonitoring(camListItem: $0) }
        }
    }
    
    private lazy var locationSubscriber: CommonLocationSubscriber = {
        let subscriber = CommonLocationSubscriber()
        subscriber.accuracy = kCLLocationAccuracyThreeKilometers
        subscriber.isLocationActiveInBackground = true
        subscriber.updateSignificantLocation = { (location) in
            // Scenario 1: Nothing has been set yet. Initiate an update.
            guard let previousLocationOfUpdating = self.previousLocationOfUpdating else {
                self.updateGeofences(location: location)
                return
            }
            
            // Scenario 2: Number of geofences is below limit
            guard let distance = self.previousDistanceToFirstSkippedItem else {
                return
            }
            
            // Scenario 3: Number of geofences is above limit
            // Update if items were skipped and the distance to the last location of update is within 90% of the original distance to the first skipped item.
            if location.distance(from: previousLocationOfUpdating) > distance * 0.9 {
                self.updateGeofences(location: location)
            }
        }
        return subscriber
    }()
    

    override init() {
    }
    
    private func updateGeofences(location: CLLocation) {
        locationSubscriber.disable()
        
        currentDistances = [:]
        items.forEach { (item) in
            currentDistances[item.id] = CLLocation(latitude: item.coordinate.latitude, longitude: item.coordinate.longitude).distance(from: location)
        }
        
        let sortedItems = items.sorted {
            guard let a = currentDistances[$0.id], let b = currentDistances[$1.id] else {return false}
            return a < b
        }
        
        alertItems = Array(sortedItems.prefix(kGeofenceLimit))


        previousLocationOfUpdating = location
        if sortedItems.count > kGeofenceLimit, let distance = currentDistances[sortedItems[kGeofenceLimit].id] {
            previousDistanceToFirstSkippedItem = distance
            locationSubscriber.enable()
        }
        else {
            previousDistanceToFirstSkippedItem = 0
        }
        
    }

    func enable() {
        locationSubscriber.enable()
    }
    
    func disable() {
        alertItems = []
        locationSubscriber.disable()
    }
    
    private func startMonitoring(camListItem: CameraListItem) {
        CommonLocationManager.shared.startMonitoring(for: camListItem.region)
    }
}
