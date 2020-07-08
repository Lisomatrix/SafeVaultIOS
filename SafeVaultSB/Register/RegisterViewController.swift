//
//  RegisterViewController.swift
//  SafeVaultSB
//
//  Created by Tiago Lima on 03/07/2020.
//  Copyright © 2020 Tiago Lima. All rights reserved.
//

import UIKit
import CoreData

class RegisterViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var repasswordTextField: UITextField!
    
    @IBOutlet weak var registerBtn: UIButton!
    @IBOutlet weak var haveAccountBtn: UIButton!
    
    @IBOutlet weak var logoImage: UIImageView!
    
    private var cryptoHelper: CryptoHelper!
    private var accountRepository: AccountRepository!
    private var vaultFileRepository: VaultFileRepository!
    
    
    private func initialize() {
        let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
                      
        self.accountRepository = appDelegate.accountRepository
        self.vaultFileRepository = appDelegate.vaultFileRepository
        self.cryptoHelper = appDelegate.cryptoHelper
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initialize()
        
        self.passwordTextField.delegate = self
        self.repasswordTextField.delegate = self
        
        let isDarkTheme = traitCollection.userInterfaceStyle == .dark
        
        if isDarkTheme {
            self.view.layer.backgroundColor = UIColor.black.cgColor
            self.logoImage.image = #imageLiteral(resourceName: "logoDark")
        }
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        animateViewMoving(up: true, moveValue: 100)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        animateViewMoving(up: false, moveValue: 100)
    }
    
    // Lifting the view up
    // Got this from stack overflow
    // The fact that I need to do such thing is stupid by itself
    func animateViewMoving (up:Bool, moveValue :CGFloat) {
        let movementDuration: TimeInterval = 0.3
        let movement:CGFloat = (up ? -moveValue : moveValue)
        UIView.beginAnimations("animateView", context: nil)
        UIView.setAnimationBeginsFromCurrentState(true)
        UIView.setAnimationDuration(movementDuration)
        self.view.frame = self.view.frame.offsetBy(dx: 0, dy: movement)
        UIView.commitAnimations()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.passwordTextField {
            self.repasswordTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        
        return true
    }
    
    /// Return back to login page
    @IBAction func haveAccountBtnPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func validate() -> Bool {
        let password = self.passwordTextField.text
        let repassword = self.repasswordTextField.text
        
        return password != nil && repassword != nil &&
                !password!.isEmpty && !repassword!.isEmpty &&
                password == repassword
    }
    
    @IBAction func onRegisterBtnPressed(_ sender: Any) {
        
        if !self.validate() {return}
        
        let password = self.passwordTextField.text!
        self.passwordTextField.text = ""
        self.repasswordTextField.text = ""
        
        self.register(password: password)
    }
    
    private func register(password: String) {
        self.clearData()
        
        let account = self.accountRepository.createAccount(password: self.passwordTextField.text!)
        
        self.cryptoHelper.saveOnKeyChain(accountId: account.accountID!, password: account.password!)
        print(account.accountID!)
               
               
        UserDefaults.standard.set(true, forKey: "hasAccount")
        
        self.showIntro()
    }
    
    private func showIntro() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let introController = storyboard.instantiateViewController(withIdentifier: "intro")
        
        introController.modalPresentationStyle = .fullScreen
        introController.modalTransitionStyle = .coverVertical
        
        self.present(introController, animated: true, completion: nil)
    }
    
     // Clear all previous data
    private func clearData() {
        // Delete Core Data
        self.accountRepository.deletePreviousAccounts()
        self.vaultFileRepository.deletePreviousFiles()
        // Delete files
        self.deleteFilesInDocumentsFolder()
    }
    
    // Delete all files in documents folder
    // Yup name explains itself
    private func deleteFilesInDocumentsFolder() {
        // Super expensive operation would block UI
        DispatchQueue.global(qos: .background).async {
            let fileManager = FileManager.default
            let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
            let documentsPath = documentsUrl.path
            
            do {
                if let documentPath = documentsPath
                {
                    let fileNames = try fileManager.contentsOfDirectory(atPath: "\(documentPath)")
                    for fileName in fileNames {
                        let filePathName = "\(documentPath)/\(fileName)"
                        try fileManager.removeItem(atPath: filePathName)
                    }
                }

            } catch {
                print("Could not clear folder: \(error)")
            }
        }
    }
}
