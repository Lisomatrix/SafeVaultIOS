//
//  BiometricsHelper.swift
//  SafeVaultSB
//
//  Created by Tiago Lima on 06/07/2020.
//  Copyright © 2020 Tiago Lima. All rights reserved.
//

import Foundation
import BiometricAuthentication
import UIKit


protocol BiometricsHelperDelegate {
    func unauthorized()
    func authorized()
}

class BiometricsHelper {
    
    var authWarned = false
    var alertHelper: AlertHelper?
    
    var delegate: BiometricsHelperDelegate?
    
    func checkBiometrics() {
        
        if authWarned {return}
        
        authWarned = true
        
        if self.canAuthenticate() {
            
            if !self.isFaceIDEnabled() {
                
                self.alertHelper?.showGotoSettingsAlert(title: "Alert", message: "Please enabled FaceID")
            }
            
            if !self.isTouchIDEnabled() {
                self.alertHelper?.showGotoSettingsAlert(title: "Alert", message: "Please enabled TouchID")
            }
        } else {
            self.alertHelper?.showGotoSettingsAlert(title: "Alert", message: "Please enable a password on your device")
        }
    }
    
    func canAuthenticate() -> Bool {
        return BioMetricAuthenticator.canAuthenticate()
    }
    
    // If the user has faceID and not actived then return false
    // Case device doesn't support then return true
    private func isFaceIDEnabled() -> Bool {
        let biometricAuth = BioMetricAuthenticator.shared
        
        let supportsFaceID = biometricAuth.isFaceIdDevice()
        let isFaceIDEnabled = biometricAuth.faceIDAvailable()
        
        if supportsFaceID && !isFaceIDEnabled {
            return false
        }
        
        return true
    }
    
    // If the user has touchID and not actived then return false
    // Case device doesn't support then return true
    private func isTouchIDEnabled() -> Bool {
        let biometricAuth = BioMetricAuthenticator.shared
        
        let supportsTouchID = biometricAuth.touchIDAvailable()
        let isTouchIDEnabled = biometricAuth.touchIDAvailable()
        
        if supportsTouchID && !isTouchIDEnabled {
            return false
        }
        
        return true
    }
    
    // show passcode authentication
    private func showPasscodeAuthentication(message: String) {
        
        BioMetricAuthenticator.authenticateWithPasscode(reason: message) { (result) in
            switch result {
            case .failure(let error):
                print(error.message())
            default:
                break
            }
        }
    }
    
    func biometricAuthentication(reason: String) {
        // Set AllowableReuseDuration in seconds to bypass the authentication when user has just unlocked the device with biometric
        BioMetricAuthenticator.shared.allowableReuseDuration = 30
        
        // start authentication
        BioMetricAuthenticator.authenticateWithBioMetrics(reason: reason) { [weak self] (result) in
                
            switch result {
            case .success( _):
                self?.delegate?.authorized()
                break
                
            case .failure(let error):
                
                switch error {
                    
                // device does not support biometric (face id or touch id) authentication
                case .biometryNotAvailable:
                    self?.showPasscodeAuthentication(message: error.message())
                    self?.delegate?.unauthorized()
                    break
                    
                // No biometry enrolled in this device, ask user to register fingerprint or face
                case .biometryNotEnrolled:
                    self?.delegate?.unauthorized()
                    self?.alertHelper?.showGotoSettingsAlert(message: error.message())
                    break
                    
                // show alternatives on fallback button clicked
                case .fallback:
                    self?.showPasscodeAuthentication(message: error.message())
                    break
                    
                    // Biometry is locked out now, because there were too many failed attempts.
                // Need to enter device passcode to unlock.
                case .biometryLockedout:
                    self?.showPasscodeAuthentication(message: error.message())
                    break
                    
                case .canceledBySystem, .canceledByUser:
                    self?.delegate?.unauthorized()
                    break
                
                // show error for any other reason
                default:
                    self?.delegate?.unauthorized()
                    self?.alertHelper?.showErrorAlert(message: error.message())
                }
            }
        }
    }
}
