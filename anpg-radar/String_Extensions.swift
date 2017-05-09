//
//  String_Extensions.swift
//  anpg-radar
//
//  Created by Esben von Buchwald on 30/04/2017.
//  Copyright © 2017 Esben von Buchwald. All rights reserved.
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "N/A")
    }
}
