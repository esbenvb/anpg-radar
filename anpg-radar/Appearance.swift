//
//  Appearance.swift
//  anpg-radar
//
//  Created by Esben von Buchwald on 24/04/2017.
//  Copyright © 2017 Esben von Buchwald. All rights reserved.
//

import Foundation
import UIKit


struct Appearance {
    static var blackTransparent = UIColor.black.withAlphaComponent(0.8)
    
    static func applyTheme(window: UIWindow) {
        let tintColor = window.rootViewController?.view.tintColor
        
        OverlayView.appearance().backgroundColor = blackTransparent
        OverlayView.appearance().cornerRadius = 8
        UILabel.appearance(whenContainedInInstancesOf: [OverlayView.self]).textColor = .white
        FolloLocationButton.appearance().setTitleColor(tintColor, for: .normal)
        UINavigationBar.appearance().backgroundColor = .black
        
    }
}
