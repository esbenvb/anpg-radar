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
    var updateSignificantLocation: ((_ location: CLLocation) -> ())?
    var didEnterRegion: ((_ region: CLRegion) -> ())?
    var didExitRegion: ((_ region: CLRegion) -> ())?
    var accuracy: CLLocationAccuracy = 1000000
    var isLocationActiveInBackground: Bool = false
    var grantedAuthorization: (() -> ())?

    
    func enable() throws {
        try CommonLocationManager.shared.subscribe(self)
    }
    
    func disable() {
        CommonLocationManager.shared.unsubscribe(self)
    }
}

enum CommonLocationError: Error {
    case locationNotGrantedWhenInuse
    case locationNotGrantedAlways
    case locationNotDetermined
    case locationUpdatesNotSupported
    case significantLocationUpdatesNotSupported
    case monitoringNotAvailable
    
    var alert: CommonLocationErrorAlert {
        switch (self) {
        case .locationNotGrantedWhenInuse:
            return CommonLocationErrorAlert(title: "Needs access when in use", closeButtonLabel: "Close", message: "The feature requires location access when the app is in use. Activate it on the settings page.", secondButtonLabel: "Settings", secondButtonHandler: CommonLocationManager.openAppSettings)
            
        case .locationNotGrantedAlways:
            return CommonLocationErrorAlert(title: "Needs access when in use", closeButtonLabel: "Close", message: "The feature requires location access, when the app is in the background. Activate it on the settings page.", secondButtonLabel: "Settings", secondButtonHandler: CommonLocationManager.openAppSettings)
            
        case .locationNotDetermined:
            return CommonLocationErrorAlert(title: "Not available", closeButtonLabel: "Close", message: "You need to allow location access for this app FIXME.", secondButtonLabel: nil, secondButtonHandler: nil)
            
        case .locationUpdatesNotSupported:
            return CommonLocationErrorAlert(title: "Not available", closeButtonLabel: "Close", message: "Location updates are not supported by your device", secondButtonLabel: nil, secondButtonHandler: nil)
            
        case .significantLocationUpdatesNotSupported:
            return CommonLocationErrorAlert(title: "Not available", closeButtonLabel: "Close", message: "Significant location changes are not supported by your device", secondButtonLabel: nil, secondButtonHandler: nil)
            
        case .monitoringNotAvailable:
            return CommonLocationErrorAlert(title: "Not available", closeButtonLabel: "Close", message: "Monitoring is not supported by your device", secondButtonLabel: nil, secondButtonHandler: nil)
        }
    }
}

class CommonLocationManager: NSObject {

    static func openAppSettings() {
        guard let url = URL(string: UIApplicationOpenSettingsURLString) else {return}
        UIApplication.shared.open(url)
    }
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    var grantedAuthorizationCallback: (() -> ())?
    
    let locationManager = CLLocationManager()

    static let shared = CommonLocationManager()
    
    var subscribers: [CommonLocationSubscriber] = [] {
        didSet {
            updateAccuracy()
            print("stopping")
            locationManager.stopUpdatingLocation()
            locationManager.stopMonitoringSignificantLocationChanges()
            let locationSubscribersExist = subscribers.contains { (subscriber) -> Bool in
                return subscriber.updateLocation != nil
            }
            let significantLocationSubscribersExist = subscribers.contains { (subscriber) -> Bool in
                return subscriber.updateSignificantLocation != nil
            }
            if locationSubscribersExist {
                locationManager.startUpdatingLocation()
                print("more than 0 location, starting")
            } else if significantLocationSubscribersExist {
                locationManager.startMonitoringSignificantLocationChanges()
                print("more than 0 siginificant location, starting significant only")
            } else {
                print("0, not starting")
            }

            print(locationManager.desiredAccuracy.description)
        }
    }
//http://stackoverflow.com/questions/25188965/ios8-location-how-should-one-request-always-authorization-after-user-has-grante
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
    
    func subscribe(_ subscriber: CommonLocationSubscriber) throws {
        print("subscribe: \(subscriber.self)")
        
        let useLocation = subscriber.updateLocation != nil
        let useSignificantLocation = subscriber.updateSignificantLocation != nil
        let background = subscriber.isLocationActiveInBackground

        if useLocation {
            guard CLLocationManager.locationServicesEnabled() else {
                throw CommonLocationError.locationUpdatesNotSupported
            }
        }
        
        if useSignificantLocation {
            guard CLLocationManager.significantLocationChangeMonitoringAvailable() else {
                throw CommonLocationError.significantLocationUpdatesNotSupported
            }
        }
        
        if useLocation || useSignificantLocation {
            if CLLocationManager.authorizationStatus() == .notDetermined {
                // ask for permission
                if isAppSupportingBackgroundLocation {
                    locationManager.requestAlwaysAuthorization()
                }
                else {
                    locationManager.requestWhenInUseAuthorization()
                }
                grantedAuthorizationCallback = subscriber.grantedAuthorization
                throw CommonLocationError.locationNotDetermined
                
            }
            if background {
                grantedAuthorizationCallback = subscriber.grantedAuthorization
                guard CLLocationManager.authorizationStatus() == .authorizedAlways else {
                    print ("NEEDS TO GRANT always ACCESS") // FIXME
                    grantedAuthorizationCallback = subscriber.grantedAuthorization
                    throw CommonLocationError.locationNotGrantedAlways
                }
            }
            else {
                guard CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() ==  .authorizedWhenInUse else {
                    print ("NEEDS TO GRANT when in use ACCESS") // FIXME
                    throw CommonLocationError.locationNotGrantedWhenInuse
                }
            }
            
        }
        
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
    
    func startMonitoring(for region: CLRegion) throws {
        if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            print("NOT SUPPORTED ON DEVICE") // FIXME
            throw CommonLocationError.monitoringNotAvailable
        }
        locationManager.startMonitoring(for: region)
    }
    
    func stopMonitoring(for region: CLRegion) {
        locationManager.stopMonitoring(for: region)
    }
    
    func stopMonitoringAll() {
        locationManager.monitoredRegions.forEach { CLLocationManager().stopMonitoring(for: $0) }
    }
    
    var isAppSupportingBackgroundLocation: Bool {
        guard let backgroundModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] else {
            return false
        }
        return backgroundModes.contains("location")
    }
    
    var isLocationAvailable: Bool {
        return CLLocationManager.locationServicesEnabled() && (CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways)
    }
}

extension CommonLocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // FIXME
        guard let location = manager.location else {return}

        print(location)
        
        let background = UIApplication.shared.applicationState == .background || UIApplication.shared.applicationState == .inactive

        subscribers.forEach { (subscriber) in
            // Skip non backgrounded items if running in background
            if !background || subscriber.isLocationActiveInBackground {
                subscriber.updateLocation?(location)
                subscriber.updateSignificantLocation?(location)
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
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            grantedAuthorizationCallback?()
            grantedAuthorizationCallback = nil
        default:
            return
        }
    }
    
}
