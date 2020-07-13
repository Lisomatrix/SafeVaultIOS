//
//  RegisterViewController.swift
//  SafeVaultSB
//
//  Created by Tiago Lima on 03/07/2020.
//  Copyright © 2020 Tiago Lima. All rights reserved.
//

import UIKit
import CoreData
import Network

class RegisterViewController: UIViewController, UITextFieldDelegate, NetworkAuthDelegate {

    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var repasswordTextField: UITextField!
    
    @IBOutlet weak var registerBtn: UIButton!
    @IBOutlet weak var haveAccountBtn: UIButton!
    
    @IBOutlet weak var logoImage: UIImageView!
    
    @IBOutlet weak var errorLabel: UILabel!
    
    private var cryptoHelper: CryptoHelper!
    private var accountRepository: AccountRepository!
    private var vaultFileRepository: VaultFileRepository!
    
    let networkAuthHandler = NetworkAuthHandler()
    let networkStatusHelper = NetworkStatusHelper()
    
    var unhashedPassword: String = ""
    
    var isConnectionAvailable = false
    
    private func initialize() {
        let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
                      
        self.accountRepository = appDelegate.accountRepository
        self.vaultFileRepository = appDelegate.vaultFileRepository
        self.cryptoHelper = appDelegate.cryptoHelper
        
        self.networkAuthHandler.delegate = self
        self.networkStatusHelper.delegate = self
        
        self.networkStatusHelper.initializeNetworkMonitor()
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
    
    private func setEnabled(enabled: Bool) {
        self.registerBtn.isEnabled = enabled
        self.passwordTextField.isEnabled = enabled
        self.repasswordTextField.isEnabled = enabled
    }
    
    private func register(password: String) {
        let clearHelper = ClearHelper()
        clearHelper.clearData()
        
        self.unhashedPassword = password
        
        let account = self.accountRepository.createAccount(password: password)
        
        self.networkAuthHandler.register(accountID: account.accountID!, password: account.password!)
        
        self.setEnabled(enabled: false)
        UserDefaults.standard.set(account.accountID!, forKey: "accountID")
    }
    
    func onAuthenticated(_ token: String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.isServerAuthenticated = true
        
        // Save token
        self.cryptoHelper.saveTokenOnKeyChain(token: token)
    }
    
    func onAuthenticationFail(_ error: String) {
        self.setEnabled(enabled: false)
        self.errorLabel.text = "Error creating account"
    }
    
    func onRegister(permanentToken: String) {
        self.cryptoHelper.savePermanentTokenOnKeyChain(token: permanentToken)
        
        let account = self.accountRepository.getAccount()!
        
        self.cryptoHelper.saveOnKeyChain(accountId: account.accountID!, password: self.unhashedPassword)
        self.unhashedPassword = ""
               
        UserDefaults.standard.set(true, forKey: "hasAccount")
        
        self.showIntro()
    }
    
    func onRegisterFail(_ error: String) {
        self.setEnabled(enabled: true)
        self.errorLabel.text = "Error creating account"
    }
    
    private func showIntro() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let introController = storyboard.instantiateViewController(withIdentifier: "intro")
        
        introController.modalPresentationStyle = .fullScreen
        introController.modalTransitionStyle = .coverVertical
        
        self.present(introController, animated: true, completion: nil)
    }
}

extension RegisterViewController: NetworkStatusDelegate {
    func onNetworkAvailable() {
        DispatchQueue.main.async {
            self.setEnabled(enabled: true)
            self.errorLabel.text = ""
        }
    }
    
    func onNetworkNotAvailable() {
        DispatchQueue.main.async {
            self.setEnabled(enabled: false)
            self.errorLabel.text = "Internet connection is needed!"
        }
    }
}
