//
//  CameraBottomView.swift
//  ANPG Radar
//
//  Created by Esben von Buchwald on 01/12/2016.
//  Copyright © 2016 Esben von Buchwald. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

class CameraBottomView: UIStackView {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var ownerLabel: UILabel!
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var headingImageView: UIImageView!

    var cameraListItem: CameraListItem? {
        didSet {
            guard let cameraListItem = cameraListItem else {return}
            idLabel.text = String(cameraListItem.id)
            ownerLabel.text = cameraListItem.operatur
            cityLabel.text = cameraListItem.address2
            addressLabel.text = cameraListItem.address1
            imageView.image = Constants.noImageImage

            DispatchQueue.global(qos: .userInitiated).async {
                if let image = cameraListItem.image {
                    DispatchQueue.main.async {
                        self.imageView.image = image
                        print(self.bounds)
                    }
                } else {
                    self.imageView.image = Constants.noImageImage
                }
            }

            updateDistance()
        }
    }
    var currentPosition: CLLocation? {
        didSet {
            updateDistance()
            updateHeading()
        }
    }
    
    var currentHeading: CLHeading? {
        didSet {
            updateHeading()
        }
    }
    
    func updateHeading() {
        guard let heading = currentHeading?.trueHeading, let location = currentPosition, let lat = cameraListItem?.lat, let lon = cameraListItem?.lon else {return}
        let camLocation = CLLocation(latitude: lat, longitude: lon)
        let bearing = Int(camLocation.bearing(to: location))
        let shownHeading = (360 + 180 + (bearing - Int(heading))) % 360
        print(shownHeading)
        headingImageView.transform = CGAffineTransform(rotationAngle: CGFloat(shownHeading).toRadians)

    }

    class func viewFromNib() -> CameraBottomView {
        guard let view = Bundle(for: self).loadNibNamed("CameraBottomView", owner: nil, options: nil)?.first as? CameraBottomView else {
            fatalError("Error loading CameraBottomView")
        }
        // God knows why this is necessary?
        view.headingImageView.tintColor = view.tintColor
        return view
    }

    func updateDistance() {
        guard let coordinate = cameraListItem?.coordinate, let currentPosition = currentPosition else {return}
        let rawDistance = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude).distance(from: currentPosition)

        let distance = Measurement(value: rawDistance, unit: UnitLength.meters)
        let formatter = MeasurementFormatter()
        formatter.locale = Locale.current
        distanceLabel.text = formatter.string(from: distance)
    }
}

extension FloatingPoint {
    var toRadians: Self { return self * .pi / 180 }
    var toDegrees: Self { return self * 180 / .pi }
}

extension CLLocation {
    func bearing(to location: CLLocation) -> CLLocationDirection {
        let lat1 = self.coordinate.latitude.toRadians
        let lon1 = self.coordinate.longitude.toRadians

        let lat2 = location.coordinate.latitude.toRadians
        let lon2 = location.coordinate.longitude.toRadians
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)
        return radiansBearing.toDegrees
    }
}
