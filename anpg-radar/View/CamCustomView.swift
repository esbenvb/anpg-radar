//
//  CamCustomView.swift
//  ANPG Radar
//
//  Created by Esben von Buchwald on 24/11/2016.
//  Copyright © 2016 Esben von Buchwald. All rights reserved.
//

import UIKit
import CoreLocation

class CamCustomView: UIStackView {

    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    var camListItem: CameraListItem?

    class func create(cameraItem: CameraListItem) -> CamCustomView {
        guard let view = Bundle(for: self).loadNibNamed("CamCustomView", owner: nil, options: nil)?.first as? CamCustomView else {fatalError("error loading CamCustomView")}

        view.descriptionLabel.text = String(cameraItem.id)
        view.camListItem = cameraItem

        return view
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        print(bounds)
        DispatchQueue.global(qos: .userInitiated).async {
            if let image = self.camListItem?.image {
                DispatchQueue.main.async {
                    self.imageView.image = image
                    print(self.bounds)
                }
            } else {
                self.imageView.image = Constants.noImageImage
            }
        }

        guard let camListItem = camListItem else {return}
        let location = CLLocation(latitude: camListItem.coordinate.latitude, longitude: camListItem.coordinate.longitude)
        GeoTools.decodePosition(location: location) { [weak self]
            (address, city) in
            self?.addressLabel.text = address
            self?.cityLabel.text = city

        }
        print("didMovetoSuperview")
    }
}
