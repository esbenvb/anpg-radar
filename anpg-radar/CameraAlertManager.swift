//
//  CameraAlertManager.swift
//  anpg-radar
//
//  Created by Esben von Buchwald on 06/03/2017.
//  Copyright © 2017 Esben von Buchwald. All rights reserved.
//

import UIKit
import CoreLocation
import UserNotifications

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
    
    var isEnabled = false {
        didSet  {
            UserDefaults().set(isEnabled, forKey: Constants.notificationSettingIdentifier)
        }
    }
    
    private var currentDistances: [String : CLLocationDistance] = [:]
    private var previousLocationOfUpdating: CLLocation?
    private var previousDistanceToFirstSkippedItem: CLLocationDistance?
    private var alertItems: [CameraListItem] = [] {
        didSet {
            CommonLocationManager.shared.stopMonitoringAll()
            alertItems.forEach {
                do {
                    try startMonitoring(camListItem: $0)
                    print("installed \($0.description)")
                }
                catch {
                    print("error alert item \($0.description)")
                }
            }
        }
    }
    
    private lazy var locationSubscriber: CommonLocationSubscriber = {
        let subscriber = CommonLocationSubscriber()
        subscriber.accuracy = kCLLocationAccuracyThreeKilometers
        subscriber.isLocationActiveInBackground = true
        subscriber.updateSignificantLocation = {[weak self] (location) in
            guard let sself = self else {return}
            
            guard sself.isEnabled else {
                return
            }
            // Only update if list has content
            guard sself.items.count > 0 else {
                sself.alertItems = []
                return
            }
            
            // Scenario 1: Nothing has been set yet. Initiate an update.
            guard let previousLocationOfUpdating = sself.previousLocationOfUpdating else {
                sself.updateGeofences(location: location)
                return
            }
            
            // Scenario 2: Number of geofences is below limit, so a distance has not been set yet.
            guard let distance = sself.previousDistanceToFirstSkippedItem else {
                return
            }
            
            // Scenario 3: Number of geofences is above limit
            // Update if items were skipped and the distance to the last location of update is within 90% of the original distance to the first skipped item.
            if location.distance(from: previousLocationOfUpdating) > distance * 0.9 {
                sself.updateGeofences(location: location)
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
        if sortedItems.count > kGeofenceLimit, let distance = currentDistances[sortedItems[kGeofenceLimit].id], locationSubscriber.enable() {
            previousDistanceToFirstSkippedItem = distance
        }
        else {
            previousDistanceToFirstSkippedItem = 0
        }
        
    }

    func enable(messageDelegate: CommonLocationMessageDelegate, grantedLocationCallback: (()->())? = nil) -> Bool {
        previousLocationOfUpdating = nil
        previousDistanceToFirstSkippedItem = 0
        locationSubscriber.grantedAuthorization = grantedLocationCallback
        locationSubscriber.messageDelegate = messageDelegate
        guard locationSubscriber.enable() else {return false}
        isEnabled = true
        return true
    }
    
    func disable() {
        alertItems = []
        locationSubscriber.disable()
        isEnabled = false
    }
    
    private func startMonitoring(camListItem: CameraListItem) throws {
        try CommonLocationManager.shared.startMonitoring(for: camListItem.region)
    }
    
    func setupNotifications(delegate: UNUserNotificationCenterDelegate) {
        let category: UNNotificationCategory = {
            let action = UNNotificationAction(identifier: "action ID", title: "action title", options: [.foreground])
            let category = UNNotificationCategory(identifier: Constants.notificationCategoryId, actions: [action], intentIdentifiers: [], options: [])
            return category
        }()
        
        let unc = UNUserNotificationCenter.current()
        
        unc.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            print(granted ? "granted" : "not granted")
            print(error?.localizedDescription ?? "NA")
        }
        unc.removeAllPendingNotificationRequests()
        
        unc.setNotificationCategories([category])
        unc.delegate = delegate
    }
}
