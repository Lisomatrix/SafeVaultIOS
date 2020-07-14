//
//  NetworkAuthHandler.swift
//  SafeVaultSB
//
//  Created by Tiago Lima on 10/07/2020.
//  Copyright © 2020 Tiago Lima. All rights reserved.
//

import Foundation
import Alamofire

protocol NetworkAuthDelegate {
    func onAuthenticated(_ token: String)
    func onAuthenticationFail(_ error: String)
    
    func onRegister(permanentToken: String)
    func onRegisterFail(_ error: String)
}

// Make register funcs optional
extension NetworkAuthDelegate {
    func onRegister(permanentToken: String) {}
    func onRegisterFail(_ error: String) {}
}


// WARNING: NSAllowsArbitraryLoads is enabled, should be disable
// as soon as I don't need it
class NetworkAuthHandler {
    //let baseURL = "http://localhost:8080/auth/"
    let baseURL = "http://192.168.1.12:8080/auth/"
    var delegate: NetworkAuthDelegate? = nil
    
    var isAuthenticated: Bool {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        return appDelegate.isServerAuthenticated
    }
    
    // User permanent token to authenticate
    func requestToken(permanentToken: String) {
        let tokenRequest = TokenRequest(permanentToken: permanentToken)
        
        AF.request(
            baseURL + "token",
            method: .post,
            parameters: tokenRequest,
            encoder: JSONParameterEncoder.default
        ).response { response in self.handleTokenResponse(response)}
    }
    
    // Authenticate on the server and get token
    func authenticate(accountID: String, password: String) {
        let authRequest = AuthRequest(username: accountID, password: password)
        
        AF.request(
            baseURL + "login",
            method: .post,
            parameters: authRequest,
            encoder: JSONParameterEncoder.default
            ).response { response in self.handleTokenResponse(response)}
    }
    
    // Func to handle repeated code when receiving token
    private func handleTokenResponse(_ response: AFDataResponse<Data?>) {
        if response.data == nil || response.error != nil {
            self.delegate?.onAuthenticationFail("Request error")
            return
        }
                   
        let decoder = JSONDecoder()
                   
        do {
            let data = try decoder.decode(AuthResponse.self, from: response.data!)
                       
            self.delegate?.onAuthenticated(data.token)
        } catch {
            self.delegate?.onAuthenticationFail("\(error)")
        }
    }
    
    // Request to regist
    func register(accountID: String, password: String) {
        let authRequest = AuthRequest(username: accountID, password: password)
        
        AF.request(
            baseURL + "register",
            method: .post,
            parameters: authRequest,
            encoder: JSONParameterEncoder.default
        ).response { response in
                  
            if response.data == nil || response.error != nil {
                self.delegate?.onRegisterFail("Request error")
                return
            }
            
            let decoder = JSONDecoder()
                      
            do {
                let data = try decoder.decode(RegisterResponse.self, from: response.data!)
                
                self.delegate?.onRegister(permanentToken: data.token)
                self.authenticate(accountID: accountID, password: password)
            } catch {
                self.delegate?.onAuthenticationFail("\(error)")
            }
        }
    }
}
