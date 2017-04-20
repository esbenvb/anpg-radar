//
//  Alert_UIViewController_Extension.swift
//  anpg-radar
//
//  Created by Esben von Buchwald on 18/04/2017.
//  Copyright © 2017 Esben von Buchwald. All rights reserved.
//

import UIKit

typealias CommonLocationErrorAlert = (title: String, closeButtonLabel: String, message: String?, secondButtonLabel: String?, secondButtonHandler: (()->())?)

extension UIViewController: CommonLocationMessageDelegate {
    func showLocationErrorAlert(_ alert: CommonLocationErrorAlert, closeAction: (()->())? = nil) {
        let ac = UIAlertController(title: alert.title, message: alert.message, preferredStyle: .alert)
        
        let closeButton = UIAlertAction(title: alert.closeButtonLabel, style: .cancel) { (action) in
            closeAction?()
            ac.dismiss(animated: true, completion: nil)
        }
        
        ac.addAction(closeButton)
        
        if let label = alert.secondButtonLabel, let customHandler = alert.secondButtonHandler {
            let action = UIAlertAction(title: label, style: .default, handler:  { (action) in
                customHandler()
                ac.dismiss(animated: true, completion: nil)
            })
            ac.addAction(action)
        }
        
        present(ac, animated: true, completion: nil)
    }
    
    func handleError(_ error: CommonLocationError, closeAction: (()->())? = nil) {
        showLocationErrorAlert(error.alert, closeAction: closeAction)
    }
}
