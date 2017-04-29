//
//  InfoPageHeaderTableViewCell.swift
//  anpg-radar
//
//  Created by Esben von Buchwald on 29/04/2017.
//  Copyright © 2017 Esben von Buchwald. All rights reserved.
//

import UIKit

class InfoPageHeaderTableViewCell: UITableViewCell {
    @IBOutlet weak var versionLabel: UILabel!
    
    class func create() -> InfoPageHeaderTableViewCell {
        let bundle = Bundle(for: InfoPageHeaderTableViewCell.self)
        guard let view = bundle.loadNibNamed("InfoPageHeaderTableViewCell", owner: nil, options: nil)?.first as? InfoPageHeaderTableViewCell else {fatalError("Error loading InfoPageHeaderTableViewCell")}
        return view
    }
}
