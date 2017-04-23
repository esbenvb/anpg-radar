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
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            alertItems.forEach { (item) in
                item.enableWarning()
            }
        }
    }
    
    private var busy = false
    
    private lazy var significantLocationSubscriber: CommonLocationSubscriber = {
        let subscriber = CommonLocationSubscriber()
        subscriber.accuracy = kCLLocationAccuracyThreeKilometers
        subscriber.updateSignificantLocation = {[weak self] (location) in
            self?.locationUpdated(location)
        }
        return subscriber
    }()
    
    private lazy var forceLocationSubscriber: CommonLocationSubscriber = {
        let subscriber = CommonLocationSubscriber()
        subscriber.accuracy = kCLLocationAccuracyThreeKilometers
        subscriber.updateLocation = {[weak self] (location) in
            self?.updateGeofences(location: location)
        }
        return subscriber
    }()
    

    override init() {
    }
    
    private func locationUpdated(_ location: CLLocation) {
        guard isEnabled && !busy else {
            return
        }

        busy = true
        // Only update if list has content
        guard items.count > 0 else {
            alertItems = []
            busy = false
            return
        }
        
        // Scenario 1: Nothing has been set yet. Initiate an update.
        guard let previousLocationOfUpdating = previousLocationOfUpdating else {
            updateGeofences(location: location)
            busy = false
            return
        }
        
        // Scenario 2: Number of geofences is below limit, so a distance has not been set yet.
        guard let distance = previousDistanceToFirstSkippedItem else {
            busy = false
            return
        }
        
        // Scenario 3: Number of geofences is above limit
        // Update if items were skipped and the distance to the last location of update is within 90% of the original distance to the first skipped item.
        if location.distance(from: previousLocationOfUpdating) > distance * 0.9 {
            updateGeofences(location: location)
            busy = false
        }
        busy = false
    }
    
    private func updateGeofences(location: CLLocation) {
        significantLocationSubscriber.disable()
        forceLocationSubscriber.disable()

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
        if sortedItems.count > kGeofenceLimit, let distance = currentDistances[sortedItems[kGeofenceLimit].id], significantLocationSubscriber.enable() {
            previousDistanceToFirstSkippedItem = distance
        }
        else {
            previousDistanceToFirstSkippedItem = 0
        }
        
    }

    func enable(messageDelegate: CommonLocationMessageDelegate, grantedLocationCallback: (()->())? = nil) -> Bool {
        previousLocationOfUpdating = nil
        previousDistanceToFirstSkippedItem = 0
        significantLocationSubscriber.grantedAuthorization = grantedLocationCallback
        significantLocationSubscriber.messageDelegate = messageDelegate
        guard significantLocationSubscriber.enable() else {return false}
        // Force update when enabling.
        guard forceLocationSubscriber.enable() else {return false}
        isEnabled = true
        return true
    }
    
    func disable() {
        alertItems = []
        significantLocationSubscriber.disable()
        forceLocationSubscriber.disable()
        isEnabled = false
    }
    
    func forceUpdate() -> Bool {
        return forceLocationSubscriber.enable()
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
