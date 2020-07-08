//
//  AlertsExtension.swift
//  SafeVaultSB
//
//  Created by Tiago Lima on 04/07/2020.
//  Copyright © 2020 Tiago Lima. All rights reserved.
//

import Foundation
import UIKit

let CancelTitle     =   "Cancel"
let OKTitle         =   "OK"

struct AlertAction {
    
    var title: String = ""
    var type: UIAlertAction.Style? = .default
    var enable: Bool? = true
    var selected: Bool? = false
    
    init(title: String, type: UIAlertAction.Style? = .default, enable: Bool? = true, selected: Bool? = false) {
        self.title = title
        self.type = type
        self.enable = enable
        self.selected = selected
    }
}

class AlertHelper {
    
    var delegate: UIViewController?
    
    private func getAlertViewController(style: UIAlertController.Style, with title: String?, message: String?, actions: [AlertAction], showCancel: Bool, actionHandler:@escaping ((_ title: String) -> ())) -> UIAlertController {
        
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
        
        // items
        var actionItems: [UIAlertAction] = []
        
        // add actions
        for (index, action) in actions.enumerated() {
            
            let actionButton = UIAlertAction(title: action.title, style: action.type!, handler: { (actionButton) in
                actionHandler(actionButton.title ?? "")
            })
            
            actionButton.isEnabled = action.enable!
            
            if style == .actionSheet { actionButton.setValue(action.selected, forKey: "checked") }
            actionButton.setAssociated(object: index)
            
            actionItems.append(actionButton)
            alertController.addAction(actionButton)
        }
        
        // add cancel button
        if showCancel {
            let cancelAction = UIAlertAction(title: CancelTitle, style: .cancel, handler: { (action) in
                actionHandler(action.title!)
            })
            alertController.addAction(cancelAction)
        }
        return alertController
    }
    
    func showErrorAlert(message: String) {
        let okAction = AlertAction(title: OKTitle)
        let alertController = getAlertViewController(style: .alert, with: "Error", message: message, actions: [okAction], showCancel: false) { (button) in
        }
        
        self.delegate?.present(alertController, animated: true, completion: nil)
    }
    
    func showAlert(title: String, message: String) {
        
        let okAction = AlertAction(title: OKTitle)
        let alertController = getAlertViewController(style: .alert, with: title, message: message, actions: [okAction], showCancel: false) { (button) in
        }
        
        self.delegate?.present(alertController, animated: true, completion: nil)
    }
    
    public func showGotoSettingsAlert(title: String = "Error", message: String) {
        let settingsAction = AlertAction(title: "Go to settings")
        
        let alertController = getAlertViewController(style: .alert, with: title, message: message, actions: [settingsAction], showCancel: true, actionHandler: { (buttonText) in
            if buttonText == CancelTitle { return }
            
            // open settings
            let url = URL(string: UIApplication.openSettingsURLString)
            if UIApplication.shared.canOpenURL(url!) {
                UIApplication.shared.open(url!, options: [:])
            }
            
        })
        self.delegate?.present(alertController, animated: true, completion: nil)
    }
}
