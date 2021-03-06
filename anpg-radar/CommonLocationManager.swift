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
    init(messageDelegate: CommonLocationMessageDelegate? = nil) {
        super.init()
        self.messageDelegate = messageDelegate
    }
    var updateLocation: ((_ location: CLLocation) -> ())?
    var updateHeading: ((_ heading: CLHeading) -> ())?
    var updateSignificantLocation: ((_ location: CLLocation) -> ())?
    var didEnterRegion: ((_ region: CLRegion) -> ())?
    var didExitRegion: ((_ region: CLRegion) -> ())?
    var accuracy: CLLocationAccuracy = 1000000
    var isLocationActiveInBackground: Bool = false
    var grantedAuthorization: (() -> ())?
    var refusedAuthorization: (() -> ())?
    weak var messageDelegate: CommonLocationMessageDelegate?
    
    func enable() -> Bool {
        do {
            try CommonLocationManager.shared.subscribe(self)
            return true
        }
        catch (CommonLocationError.locationNotDetermined) {
            messageDelegate?.handleError(.locationNotDetermined, closeAction: {
                CommonLocationManager.shared.requestAuthorization(subscriber: self)
            })
            return false
            
        }
        catch (let error as CommonLocationError) {
            messageDelegate?.handleError(error, closeAction: nil)
            return false
        }
        catch {
            let error = CommonLocationError.unknown
            messageDelegate?.handleError(error, closeAction: nil)
            return false
        }
    }
    
    func disable() {
        CommonLocationManager.shared.unsubscribe(self)
    }
}

protocol CommonLocationMessageDelegate: class {
    func handleError(_ error: CommonLocationError, closeAction: (()->())?)
}

enum CommonLocationError: Error {
    case locationNotGrantedWhenInuse
    case locationNotGrantedAlways
    case locationNotDetermined
    case locationUpdatesNotSupported
    case significantLocationUpdatesNotSupported
    case monitoringNotAvailable
    case unknown
    
    var alert: CommonLocationErrorAlert {
        switch (self) {
        case .locationNotGrantedWhenInuse:
            return CommonLocationErrorAlert(title: "alert.title.needswheninuselocationaccess".localized, closeButtonLabel: "alert.button.close".localized, message: "alert.message.needswheninuselocationaccess.".localized, secondButtonLabel: "alert.button.settings".localized, secondButtonHandler: CommonLocationManager.openAppSettings)
            
        case .locationNotGrantedAlways:
            return CommonLocationErrorAlert(title: "alert.title.needsalwayslocationaccess".localized , closeButtonLabel: "alert.button.close".localized, message: "alert.message.needsalwayslocationaccess".localized, secondButtonLabel: "alert.button.settings".localized, secondButtonHandler: CommonLocationManager.openAppSettings)
            
        case .locationNotDetermined:
            return CommonLocationErrorAlert(title: "alert.title.needslocationaccess".localized, closeButtonLabel: "alert.button.close".localized, message: "alert.message.needslocationaccess".localized, secondButtonLabel: nil, secondButtonHandler: nil)
            
        case .locationUpdatesNotSupported:
            return CommonLocationErrorAlert(title: "alert.title.devicenotsupported".localized, closeButtonLabel: "alert.button.close".localized, message: "alert.message.locationnotavailable".localized, secondButtonLabel: nil, secondButtonHandler: nil)
            
        case .significantLocationUpdatesNotSupported:
            return CommonLocationErrorAlert(title: "alert.title.devicenotsupported".localized, closeButtonLabel: "alert.button.close".localized, message: "alert.message.significantlocationnotavailable".localized, secondButtonLabel: nil, secondButtonHandler: nil)
            
        case .monitoringNotAvailable:
            return CommonLocationErrorAlert(title: "alert.title.devicenotsupported".localized, closeButtonLabel: "alert.button.close".localized, message: "alert.message.monitoringnotavailable".localized, secondButtonLabel: nil, secondButtonHandler: nil)

        case .unknown:
            return CommonLocationErrorAlert(title: "alert.title.error".localized, closeButtonLabel: "alert.button.close".localized, message: "alert.message.unknownerror".localized, secondButtonLabel: nil, secondButtonHandler: nil)
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
    var refusedAuthorizationCallback: (() -> ())?
    
    let locationManager = CLLocationManager()

    static let shared = CommonLocationManager()
    
    var subscribers: [CommonLocationSubscriber] = [] {
        didSet {
            updateAccuracy()
            print("stopping")
            locationManager.stopUpdatingLocation()
            locationManager.stopMonitoringSignificantLocationChanges()
            locationManager.stopUpdatingHeading()
            let locationSubscribersExist = subscribers.contains { (subscriber) -> Bool in
                return subscriber.updateLocation != nil
            }
            let significantLocationSubscribersExist = subscribers.contains { (subscriber) -> Bool in
                return subscriber.updateSignificantLocation != nil
            }
            let headingSubscribersExist = subscribers.contains { (subscriber) -> Bool in
                return subscriber.updateHeading != nil
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

            if headingSubscribersExist {
                locationManager.startUpdatingHeading()
                print("updating heading")
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
    
    func requestAuthorization(subscriber: CommonLocationSubscriber) {
        // ask for permission
        if isAppSupportingBackgroundLocation {
            locationManager.requestAlwaysAuthorization()
        }
        else {
            locationManager.requestWhenInUseAuthorization()
        }
        grantedAuthorizationCallback = subscriber.grantedAuthorization
        refusedAuthorizationCallback = subscriber.refusedAuthorization
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
                throw CommonLocationError.locationNotDetermined
            }
            if background {
                // Setting these to make the desired stuff enabled when the user changes location settings
                grantedAuthorizationCallback = subscriber.grantedAuthorization
                refusedAuthorizationCallback = subscriber.refusedAuthorization
                guard CLLocationManager.authorizationStatus() == .authorizedAlways else {
                    print ("NEEDS TO GRANT always ACCESS") // FIXME
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
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
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
    
    func requestLocation() {
        locationManager.requestLocation()
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
            refusedAuthorizationCallback?()
            refusedAuthorizationCallback = nil
            return
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        subscribers.forEach { (subscriber) in
            subscriber.updateHeading?(newHeading)
        }
    }
    
}
