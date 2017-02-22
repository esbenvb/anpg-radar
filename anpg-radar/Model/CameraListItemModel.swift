//
// Created by Esben von Buchwald on 23/11/2016.
// Copyright (c) 2016 ___FULLUSERNAME___. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

class CameraListItem: NSObject, MKAnnotation {
    let id: Int64
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

    init(id: Int64, lat: Double, lon: Double, operatur: String? = nil, imageUrl: String? = nil) {

        self.id = id
        self.lat = lat
        self.lon = lon
        self.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        self.operatur = operatur
        self.imageUrl = imageUrl
        self.title = operatur ?? "N/A"
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
        self.init(id: id, lat: lat, lon: lon, operatur: tags["operator"] as? String, imageUrl: tags["image"] as? String)
    }

    var region: CLCircularRegion {
        let region = CLCircularRegion(center: coordinate, radius: CLLocationDistance(1000), identifier: String(id))
        region.notifyOnEntry = true
        return region
    }
    
}
