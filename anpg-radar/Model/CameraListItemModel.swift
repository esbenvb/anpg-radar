//
// Created by Esben von Buchwald on 23/11/2016.
// Copyright (c) 2016 ___FULLUSERNAME___. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import UserNotifications

class CameraListItem: NSObject, MKAnnotation, NSCoding {
    let id: String
    let lat: Double
    let lon: Double
    let imageUrl: String?
    let operatur: String?

    var title: String?
    var subtitle: String?
    var coordinate: CLLocationCoordinate2D
    var address1: String?
    var address2: String?

    lazy var image: UIImage? = { [weak self] in
        print("loading  image \(self?.imageUrl ?? "")")
        guard let imageUrl = self?.imageUrl, let url = URL(string: imageUrl) else {return nil}
        guard let imageData = try? Data(contentsOf: url) else {return nil}
        return UIImage(data: imageData)
    }()
    
    init(id: String, lat: Double, lon: Double, operatur: String? = nil, imageUrl: String? = nil, address1: String? = nil, address2: String? = nil) {

        self.id = id
        self.lat = lat
        self.lon = lon
        self.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        self.operatur = operatur
        self.imageUrl = imageUrl
        self.title = operatur ?? "N/A"
    }
    

    required convenience init?(coder aDecoder: NSCoder) {
        guard let id = aDecoder.decodeObject(forKey: "id") as? String else {return nil}
        let lat = aDecoder.decodeDouble(forKey: "lat")
        let lon = aDecoder.decodeDouble(forKey: "lon")
        let operatur = aDecoder.decodeObject(forKey: "operatur") as? String
        let imageUrl = aDecoder.decodeObject(forKey: "imageUrl") as? String
        let address1 = aDecoder.decodeObject(forKey: "address1") as? String
        let address2 = aDecoder.decodeObject(forKey: "address2") as? String
        self.init(id: id, lat: lat, lon: lon, operatur: operatur, imageUrl: imageUrl, address1: address1, address2: address2)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: "id")
        aCoder.encode(lat, forKey: "lat")
        aCoder.encode(lon, forKey: "lon")
        aCoder.encode(operatur, forKey: "operatur")
        aCoder.encode(imageUrl, forKey: "iamgeUrl")
        aCoder.encode(address1, forKey: "address1")
        aCoder.encode(address2, forKey: "address2")
    }
}

extension CameraListItem {
    convenience init?(json: [String: Any]) {
        guard
            let id = json["id"] as? Int64,
            let lat = json["lat"] as? Double,
            let lon = json["lon"] as? Double,
            let tags = json["tags"] as? [String: Any]
        else {
            return nil
        }
        let idString = String(id)
        self.init(id: idString, lat: lat, lon: lon, operatur: tags["operator"] as? String, imageUrl: tags["image"] as? String)
    }

    var region: CLCircularRegion {
        let region = CLCircularRegion(center: coordinate, radius: Constants.cameraRegionRadius, identifier: id)
        region.notifyOnEntry = true
        region.notifyOnExit = false
        return region
    }
    
    var notificationContent: UNNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Camera nearby!"
        content.subtitle = self.id
        if let address1 = self.address1, let address2 = self.address2 {
            content.body = "\(address1), \(address2)"
        }
        else {
            content.body = "Unknown address"
        }
        content.categoryIdentifier = Constants.notificationCategoryId
        content.sound = UNNotificationSound.default()
        content.threadIdentifier = self.id
        
        // FIXME: does not work with external URLs...
        //            if let url = URL(string: self.imageUrl ?? ""), url.startAccessingSecurityScopedResource() {
        //                do {
        //                    let image = try UNNotificationAttachment(identifier: self.id, url: url, options: [:])
        //                    content.attachments = [image]
        //                    url.stopAccessingSecurityScopedResource()
        //                }
        //                catch {
        //                    print(error.localizedDescription)
        //                }
        //                url.stopAccessingSecurityScopedResource()
        //            }
        // FIXME make action for clicking notification
        return content
    }
    
    func enableWarning() {
        let trigger = UNLocationNotificationTrigger(region: self.region, repeats: true)
        let request = UNNotificationRequest(identifier: "camNotification.\(self.id)", content: self.notificationContent, trigger: trigger)

        CLLocationManager().requestWhenInUseAuthorization()
        UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error) in
            if let error = error {
                print(error)
            }
            else {
                print("completed \(self.address1 ?? "NA") \(self.address2 ?? "NA")")
            }
        })
    }
    
    static func findById(id: String, list: [CameraListItem]) -> CameraListItem? {
        let filteredList = list.filter{ $0.id == id}
        return filteredList.first
    }
    
    static var localList: [CameraListItem]? {
        get {
            guard let listData = UserDefaults.standard.object(forKey: Constants.cameraLocalListKey) as? Data else {return nil}
            let list = NSKeyedUnarchiver.unarchiveObject(with: listData) as? [CameraListItem] ?? nil
            return list
        }
        
        set {
            guard let localList = localList else {
                UserDefaults.standard.removeObject(forKey: Constants.cameraLocalListKey)
                return
            }
            let elementsSerialized = NSKeyedArchiver.archivedData(withRootObject: localList)
            UserDefaults.standard.set(elementsSerialized, forKey: Constants.cameraLocalListKey)
            UserDefaults.standard.synchronize()
            
        }
    }

    
    static func updateAddresses(elements: [CameraListItem], completion: @escaping ([CameraListItem]) -> ()) {
        var updatedElements: [CameraListItem] = []
        elements.forEach { (element) in
            let location = CLLocation(latitude: element.coordinate.latitude, longitude: element.coordinate.longitude)
            GeoTools.decodePosition(location: location, completion: { (address1, address2) in
                element.address1 = address1
                element.address2 = address2
                updatedElements.append(element)
                
                if updatedElements.count == elements.count {
                    completion(updatedElements)
                }
            })
        }
    }
}
