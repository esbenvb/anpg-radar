//
//  OtherViewController.swift
//  anpg-radar
//
//  Created by Esben von Buchwald on 02/12/2016.
//  Copyright © 2016 Esben von Buchwald. All rights reserved.
//

import UIKit

class OtherViewController: UIViewController {

    @IBAction func closeButtonClicked(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

