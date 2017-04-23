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
    
    private lazy var locationSubscriber: CommonLocationSubscriber = {
        let subscriber = CommonLocationSubscriber()
        subscriber.accuracy = kCLLocationAccuracyThreeKilometers
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
        
        let maxItems = items.count > kGeofenceLimit ? kGeofenceLimit - 1 : kGeofenceLimit
        
        alertItems = Array(sortedItems.prefix(maxItems))


        previousLocationOfUpdating = location
        if sortedItems.count > kGeofenceLimit, let distance = currentDistances[sortedItems[kGeofenceLimit].id], locationSubscriber.enable() {
            previousDistanceToFirstSkippedItem = distance
            setupOutOfRangeWarning(location: location, distance: distance)
        }
        else {
            previousDistanceToFirstSkippedItem = 0
        }
        
    }

    private func setupOutOfRangeWarning(location: CLLocation, distance: CLLocationDistance) {
        let region = CLCircularRegion(center: location.coordinate, radius: distance, identifier: "outOfRangeWarning")
        region.notifyOnExit = true
        region.notifyOnEntry = false
        
        let content: UNNotificationContent = {
            let content = UNMutableNotificationContent()
            content.title = "Camera warnings out of range"
            content.body = "Click to open the app, this will update the warnings to your current area"
            return content
        }()
        
        let trigger = UNLocationNotificationTrigger(region: region, repeats: true)
        
        let request = UNNotificationRequest(identifier: "outOfRangeRequest", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    func enable(messageDelegate: CommonLocationMessageDelegate, grantedLocationCallback: (()->())? = nil) -> Bool {
        previousLocationOfUpdating = nil
        previousDistanceToFirstSkippedItem = 0
        locationSubscriber.grantedAuthorization = grantedLocationCallback
        locationSubscriber.messageDelegate = messageDelegate
        guard locationSubscriber.enable() else {return false}
        isEnabled = true
        CommonLocationManager.shared.requestLocation()
        return true
    }
    
    func disable() {
        alertItems = []
        locationSubscriber.disable()
        isEnabled = false
    }
    
    func setupNotifications(delegate: UNUserNotificationCenterDelegate) {
        let cameraWarning: UNNotificationCategory = {
            let action = UNNotificationAction(identifier: "action ID", title: "action title", options: [.foreground])
            let category = UNNotificationCategory(identifier: Constants.notificationCategoryId, actions: [], intentIdentifiers: [], options: [])
            return category
        }()
        
        let outOfRangeWarning: UNNotificationCategory = {
            let category = UNNotificationCategory(identifier: Constants.outOfRangeCategoryId, actions: [], intentIdentifiers: [], options: [])
            return category
        }()
        
        let unc = UNUserNotificationCenter.current()
        
        unc.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            print(granted ? "granted" : "not granted")
            print(error?.localizedDescription ?? "NA")
        }
        unc.removeAllPendingNotificationRequests()
        
        unc.setNotificationCategories([cameraWarning, outOfRangeWarning])
        unc.delegate = delegate
    }
}
