//
// Created by Esben von Buchwald on 23/11/2016.
// Copyright (c) 2016 ___FULLUSERNAME___. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

class CameraListItem: NSObject, MKAnnotation, NSCoding {
    let id: String
    let lat: Double
    let lon: Double
    let imageUrl: String?
    let operatur: String?

    var title: String?
    var subtitle: String?
    var coordinate: CLLocationCoordinate2D

    lazy var image: UIImage? = { [weak self] in
        print("loading  image \(self?.imageUrl ?? "")")
        guard let imageUrl = self?.imageUrl, let url = URL(string: imageUrl) else {return nil}
        guard let imageData = try? Data(contentsOf: url) else {return nil}
        return UIImage(data: imageData)
    }()
    
    init(id: String, lat: Double, lon: Double, operatur: String? = nil, imageUrl: String? = nil) {

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
        self.init(id: id, lat: lat, lon: lon, operatur: operatur, imageUrl: imageUrl)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: "id")
        aCoder.encode(lat, forKey: "lat")
        aCoder.encode(lon, forKey: "lon")
        aCoder.encode(imageUrl, forKey: "iamgeUrl")
        aCoder.encode(operatur, forKey: "operatur")
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
        let region = CLCircularRegion(center: coordinate, radius: CLLocationDistance(1000), identifier: String(id))
        region.notifyOnEntry = true
        return region
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
}
