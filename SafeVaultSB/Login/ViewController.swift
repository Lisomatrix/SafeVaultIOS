//
//  ViewController.swift
//  SafeVaultSB
//
//  Created by Tiago Lima on 03/07/2020.
//  Copyright © 2020 Tiago Lima. All rights reserved.
//

import UIKit
import CryptoSwift
import BiometricAuthentication
import Network


class ViewController: UIViewController, UITextFieldDelegate, BiometricsHelperDelegate, NetworkAuthDelegate {

    @IBOutlet weak var logInBtn: UIButton!
    @IBOutlet weak var accountTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
   
    @IBOutlet weak var errorLabel: UILabel!
    
    @IBOutlet weak var logoImage: UIImageView!
    
    private var hasAccount: Bool = false
    private var isLocalAuthenticated: Bool = false
    
    private var cryptoHelper: CryptoHelper!
    private var accountRepository: AccountRepository!
    
    private let alertHelper = AlertHelper()
    
    private let biometricsHelper
        = BiometricsHelper()
    
    private let networkAuthHandler = NetworkAuthHandler();
    private let networkStatusHelper = NetworkStatusHelper();
    
    private func initialize() {
        let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
        
        self.accountRepository = appDelegate.accountRepository
        self.cryptoHelper = appDelegate.cryptoHelper
        
        // Biometrics
        self.biometricsHelper.delegate = self
        self.biometricsHelper.alertHelper = self.alertHelper
        // Network Auth
        self.networkAuthHandler.delegate = self
        
        self.networkStatusHelper.initializeNetworkMonitor()
        
        // Remove previous controllers from the stack
        self.navigationController?.viewControllers.removeAll(where: { (vc) -> Bool in
            return !vc.isKind(of: ViewController.self)
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialize()
        self.accountTextField.delegate = self
        self.passwordTextField.delegate = self
        
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
    
    func onAuthenticated(_ token: String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.isServerAuthenticated = true
        
        // Save token
        self.cryptoHelper.saveTokenOnKeyChain(token: token)
        
        if !self.isLocalAuthenticated {
            let clearHelper = ClearHelper()
            clearHelper.clearData()
        }
        
        
        if !self.hasAccount && self.networkStatusHelper.isConnectionAvailable {
            let clearHelper = ClearHelper()
            clearHelper.clearData()
            UserDefaults.standard.set(true, forKey: "syncNeeded")
            UserDefaults.standard.set(true, forKey: "hasAccount")
        }
        
        
        self.goToMyFiles()
    }
    
    func onAuthenticationFail(_ error: String) {
        print("Error: \(error)")
        errorLabel.text = "AccountID or password are incorrect"
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.isServerAuthenticated = false
        
        if self.isLocalAuthenticated {
            self.goToMyFiles()
        }
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.biometricsHelper.checkBiometrics()
        
        self.hasAccount = UserDefaults.standard.value(forKey: "hasAccount") as? Bool ?? false
        
        if hasAccount && self.biometricsHelper.canAuthenticate() {
            self.biometricsHelper.biometricAuthentication(reason: "Authenticate yourself")
        }
    }
    
    func unauthorized() {
        // Do nothing
    }
    
    func authorized() {
        UserDefaults.standard.set(false, forKey: "syncNeeded")
        goToMyFiles()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.accountTextField {
            self.passwordTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
            
        return true
    }
    
    @IBAction func onLogInPressed(_ sender: UIButton) {
        // Get Input
        let password = self.passwordTextField.text!
        let accountID = self.accountTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        self.passwordTextField.text = ""
        
        let hasConnection = self.networkStatusHelper.isConnectionAvailable
        self.isLocalAuthenticated = self.authenticate(password: password, accountID: accountID)
        
        UserDefaults.standard.set(accountID, forKey: "accountID")
        
        if hasConnection {
            self.networkAuthHandler.authenticate(accountID: accountID, password: password.sha512())
        } else if self.isLocalAuthenticated {
            self.goToMyFiles()
        } else {
            errorLabel.text = "AccountID or password are incorrect"
        }
    }
    
    /// Navigate to register page
    @IBAction func onRegisterBtnPressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let registerController = storyboard.instantiateViewController(withIdentifier: "register") as! RegisterViewController
        
        registerController.modalPresentationStyle = .fullScreen
        registerController.modalTransitionStyle = .flipHorizontal
        
        self.present(registerController, animated: true, completion: nil)
    }
    
    // Attempt to authenticate
    private func authenticate(password: String, accountID: String) -> Bool {
        let hashedPassword = password.sha512()
        
        // Attempt to get account from core data
        let account = self.accountRepository.getAccount(
            accountID: accountID,
            password: hashedPassword
        )
        
        if account == nil {
            return false
        }
        
        return self.cryptoHelper.checkKeyChainPassword(
            accountID: accountID,
            hashedPassword: hashedPassword
        )
    }
    
    private func goToMyFiles() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let myFilesController = storyboard.instantiateViewController(withIdentifier: "navigation")
        
        myFilesController.modalPresentationStyle = .fullScreen
        myFilesController.modalTransitionStyle = .flipHorizontal
        
        self.present(myFilesController, animated: true, completion: nil)
    }
}
