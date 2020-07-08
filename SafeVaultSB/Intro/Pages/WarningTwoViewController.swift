//
//  WarningViewController.swift
//  SafeVaultSB
//
//  Created by Tiago Lima on 07/07/2020.
//  Copyright © 2020 Tiago Lima. All rights reserved.
//

import UIKit

class WarningTwoViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let isDarkTheme = traitCollection.userInterfaceStyle == .dark
        
        if isDarkTheme {
            self.view.backgroundColor = UIColor.black
        }
    }
    
    @IBAction func onAcceptPressed(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let accountIDController = storyboard.instantiateViewController(withIdentifier: "accountID")
        
        accountIDController.modalPresentationStyle = .fullScreen
        accountIDController.modalTransitionStyle = .flipHorizontal
        
        self.present(accountIDController, animated: true, completion: nil)
    }
}
