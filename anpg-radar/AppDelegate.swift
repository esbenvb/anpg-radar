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
import Google

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    lazy var alertManager: CameraAlertManager = {
        let alertManager = CameraAlertManager.shared
        alertManager.items = CameraListItem.localList ?? []
        return alertManager
    }()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Configure tracker from GoogleService-Info.plist.
        var configureError: NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(configureError)")
        
        // Optional: configure GAI options.
        guard let gai = GAI.sharedInstance() else {
            assert(false, "Google Analytics not configured correctly")
            return false
        }
        gai.trackUncaughtExceptions = true  // report uncaught exceptions
        #if DEBUG
        gai.logger.logLevel = GAILogLevel.verbose  // remove before app release
        #endif
        
        
        alertManager.setupNotifications(delegate: self)

        if let window = window {
            Appearance.applyTheme(window: window)
        }
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
        if UserDefaults().bool(forKey: Constants.notificationSettingIdentifier) {
            alertManager.disable()
            let _ = alertManager.enable(messageDelegate: self) // FIXME HANDLE RESULT
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    


}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("notification: \(response.description) id: \(response.notification.request.content.threadIdentifier)")
        if response.notification.request.content.categoryIdentifier == Constants.notificationCategoryId {
            guard let item = CameraListItem.findById(id: response.notification.request.content.threadIdentifier, list: alertManager.items) else {return}
            alertManager.pushNotification(item: item)
            completionHandler()
        }
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if notification.request.content.categoryIdentifier == Constants.notificationCategoryId {
            completionHandler([.alert, .sound])
        }
    }
}

extension AppDelegate: CommonLocationMessageDelegate {
    func handleError(_ error: CommonLocationError, closeAction: (()->())?) {
        print(error.localizedDescription)
        closeAction?()
        // FIXME
    }
}
