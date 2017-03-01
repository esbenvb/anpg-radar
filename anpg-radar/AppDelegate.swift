//
//  AppDelegate.swift
//  anpg-radar
//
//  Created by Esben von Buchwald on 02/12/2016.
//  Copyright © 2016 Esben von Buchwald. All rights reserved.
//

import UIKit
import CoreLocation
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let locationManager = CLLocationManager()
    var camList = UserDefaults.standard.array(forKey: "camList") as? [CameraListItem] ?? []
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        let unc = UNUserNotificationCenter.current()
        
        unc.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            print(granted ? "granted" : "not granted")
            print(error?.localizedDescription ?? "NA")
        }
        unc.removeAllPendingNotificationRequests()
        
        unc.setNotificationCategories([category])
        unc.delegate = self

        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

extension AppDelegate {

    func showNotification(item: CameraListItem) {

        if UIApplication.shared.applicationState == .active {
            let ac = UIAlertController(title: "WARNING", message: item.id, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .cancel) { (action) in
                ac.dismiss(animated: true, completion: nil)
            }
            ac.addAction(okAction)
            window?.rootViewController?.present(ac, animated: true, completion: nil)
            let notification = Notification(name: Constants.cameraDetectedNotificationName, object: item, userInfo: nil)
            NotificationCenter.default.post(notification)

        }
        else {
            // https://blog.codecentric.de/en/2016/11/setup-ios-10-local-notification/
            
            
            let location = CLLocation(latitude: item.coordinate.latitude, longitude: item.coordinate.longitude)
            GeoTools.decodePosition(location: location) { [weak self]
                (address, city) in
                let content = UNMutableNotificationContent()
                content.title = "Camera nearby!"
                content.subtitle = item.id
                content.body = "\(address), \(city)"
                content.categoryIdentifier = Constants.notificationCategoryId
                content.sound = UNNotificationSound.default()
                content.threadIdentifier = item.id
                
                // FIXME make action for clicking notification
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.001, repeats: false) // FIXME HACK
                
                let request = UNNotificationRequest(identifier: "camNotification", content: content, trigger: trigger)
                
                let unc = UNUserNotificationCenter.current()
                unc.removeAllPendingNotificationRequests()
                unc.add(request, withCompletionHandler: { (error) in
                    if let error = error {
                        print(error)
                    }
                    else {
                        print("completed")
                    }
                    
                })
                
            }
            
            
        }
        print("you enteded region \(item.id)")
    }
}

extension AppDelegate: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let item = CameraListItem.findById(id: region.identifier, list: camList) else {return}
        showNotification(item: item)
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        guard let item = CameraListItem.findById(id: response.notification.request.content.threadIdentifier, list: camList) else {return}
        let notification = Notification(name: Constants.cameraDetectedNotificationName, object: item, userInfo: nil)
        NotificationCenter.default.post(notification)

        
        completionHandler()
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler(.alert)
    }
}
