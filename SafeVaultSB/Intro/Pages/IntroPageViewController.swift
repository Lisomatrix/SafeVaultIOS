//
//  WarningOneViewController.swift
//  SafeVaultSB
//
//  Created by Tiago Lima on 07/07/2020.
//  Copyright © 2020 Tiago Lima. All rights reserved.
//

import UIKit

class IntroPageViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let isDarkTheme = traitCollection.userInterfaceStyle == .dark
        
        if isDarkTheme {
            self.view.backgroundColor = UIColor.black
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
