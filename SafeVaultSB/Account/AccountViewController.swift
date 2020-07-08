//
//  AccountViewController.swift
//  SafeVaultSB
//
//  Created by Tiago Lima on 07/07/2020.
//  Copyright © 2020 Tiago Lima. All rights reserved.
//

import UIKit

class AccountViewController: UIViewController {

    @IBOutlet weak var shadowContainer: UIView!
    @IBOutlet weak var accountIDLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!
    
    private func initialize() {
        let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
                      
        let accountRepository = appDelegate.accountRepository
        
        let account = accountRepository.getAccount()
        if  account == nil {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.accountIDLabel.text = account!.accountID!
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.initialize()
        self.setStyle()
    }
    
    private func setStyle() {
        let isDarkTheme = traitCollection.userInterfaceStyle == .dark
        
        self.shadowContainer.layer.cornerRadius = 4
        self.shadowContainer.clipsToBounds = false
        
        self.shadowContainer.layer.shadowColor = shadowColor.cgColor
        self.shadowContainer.layer.shadowOpacity = 1;
        self.shadowContainer.layer.shadowRadius = 12;
        self.shadowContainer.layer.shadowOffset = CGSize(width: 0.0, height: 3.0);
        
        self.shadowContainer.backgroundColor = UIColor(rgb: 0x00B7FF)
        self.view.backgroundColor = mainBlue
        
        if isDarkTheme {
            self.shadowContainer.backgroundColor = darkColor
            self.view.backgroundColor = UIColor.black
        }
        
        separatorView.backgroundColor = UIColor.white
    }
    
    @IBAction func onContinuePressed(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
               
        let myFilesController = storyboard.instantiateViewController(withIdentifier: "navigation")
               
        myFilesController.modalPresentationStyle = .fullScreen
        myFilesController.modalTransitionStyle = .flipHorizontal
               
        self.present(myFilesController, animated: true, completion: nil)
    }
    
    @IBAction func onCopyPressed(_ sender: UIButton) {
        UIPasteboard.general.string = self.accountIDLabel.text!
    }
}
