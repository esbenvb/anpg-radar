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
        }
    }

    class func viewFromNib() -> CameraBottomView {
        guard let view = Bundle(for: self).loadNibNamed("CameraBottomView", owner: nil, options: nil)?.first as? CameraBottomView else {
            fatalError("Error loading CameraBottomView")
        }
        return view
    }

    func updateDistance() {
        guard let coordinate = cameraListItem?.coordinate, let currentPosition = currentPosition else {return}
        let distance = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude).distance(from: currentPosition)
        distanceLabel.text = String(distance)
    }
}
