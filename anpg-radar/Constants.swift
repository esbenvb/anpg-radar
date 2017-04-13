//
//  Constants.swift
//  ANPG Radar
//
//  Created by Esben von Buchwald on 01/12/2016.
//  Copyright © 2016 Esben von Buchwald. All rights reserved.
//

import Foundation
import UIKit

struct Constants {
    static var noImageImage: UIImage? {
        let image = UIImage(named: "noImage")
        return image
    }
    
    static let cameraDetectedNotificationName = Notification.Name("CameraDetected")

    static let notificationCategoryId = "camDetected"
}

