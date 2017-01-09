//
//  GeoTools.swift
//  ANPG Radar
//
//  Created by Esben von Buchwald on 01/12/2016.
//  Copyright © 2016 Esben von Buchwald. All rights reserved.
//

import Foundation
import CoreLocation

struct GeoTools {
    static func decodePosition(location: CLLocation, completion: @escaping (_ address: String, _ city: String) -> ()) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) {
            (placemarks, error)  in
            guard let placemarks = placemarks else {return}

            guard
                let placemark = placemarks.first,
                let dictionary = placemark.addressDictionary,
                let addressLines = dictionary["FormattedAddressLines"] as? [String],
                addressLines.count >= 2
                else {return}
            completion(addressLines[0], addressLines[1])
        }

    }
}
