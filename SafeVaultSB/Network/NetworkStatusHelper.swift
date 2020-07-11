//
//  NetworkStatusHelper.swift
//  SafeVaultSB
//
//  Created by Tiago Lima on 10/07/2020.
//  Copyright © 2020 Tiago Lima. All rights reserved.
//

import Foundation
import Network
import UIKit

protocol NetworkStatusDelegate {
    func onNetworkAvailable()
    func onNetworkNotAvailable()
}

class NetworkStatusHelper {
    
    var delegate: NetworkStatusDelegate?
    
    let monitor = NWPathMonitor()
    var isConnectionAvailable = false
    
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    func initializeNetworkMonitor() {
        monitor.pathUpdateHandler = { path in
            
            if path.status == .satisfied {
                self.isConnectionAvailable = true
                self.delegate?.onNetworkAvailable()
                
            } else {
                self.isConnectionAvailable = false
                self.delegate?.onNetworkNotAvailable()
                self.appDelegate.isServerAuthenticated = false
            }
        }

        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
}
