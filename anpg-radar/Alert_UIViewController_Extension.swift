//
//  Alert_UIViewController_Extension.swift
//  anpg-radar
//
//  Created by Esben von Buchwald on 18/04/2017.
//  Copyright © 2017 Esben von Buchwald. All rights reserved.
//

import UIKit

typealias CommonLocationErrorAlert = (title: String, closeButtonLabel: String, message: String?, secondButtonLabel: String?, secondButtonHandler: (()->())?)

extension UIViewController {
    func showLocationErrorAlert(_ alert: CommonLocationErrorAlert) {
        let ac = UIAlertController(title: alert.title, message: alert.message, preferredStyle: .alert)
        
        let closeAction = UIAlertAction(title: alert.closeButtonLabel, style: .cancel) { (action) in
            ac.dismiss(animated: true, completion: nil)
        }
        
        ac.addAction(closeAction)
        
        if let label = alert.secondButtonLabel, let customHandler = alert.secondButtonHandler {
            let action = UIAlertAction(title: label, style: .default, handler:  { (action) in
                customHandler()
                ac.dismiss(animated: true, completion: nil)
            })
            ac.addAction(action)
        }
        
        present(ac, animated: true, completion: nil)
    }
    
    func showAlert(error: CommonLocationError) {
        showLocationErrorAlert(error.alert)
    }
}
