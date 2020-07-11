//
//  MyFilesNetworkHandler.swift
//  SafeVaultSB
//
//  Created by Tiago Lima on 10/07/2020.
//  Copyright © 2020 Tiago Lima. All rights reserved.
//

import Foundation
import UIKit
import Observable

extension MyFilesViewController: NetworkStatusDelegate, NetworkAuthDelegate, NetworkFileDelegate {
    
    
    func syncFiles() {
        let files = self.vaultFileRepository.getVaultFileNotSynced()
               
        if files == nil {return}
               
        for file in files! { // 8oWljWdF
            self.networkFileHandler.requestFileUpload(vaultFile: file, fileURL: file.path!)
            file.isInSync = true
            self.vaultFileRepository.saveVaultFile(vaultFile: file)
            UserDefaults.standard.set(false, forKey: "syncNeeded")
        }
    }
    
    func onAuthenticated(_ token: String) {
        self.cryptoHelper.saveTokenOnKeyChain(token: token)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.isServerAuthenticated = true
        
        DispatchQueue.global(qos: .background).async {
            self.syncFiles()
        }
    }
    
    func onAuthenticationFail(_ error: String) {
        print("Error: \(error)")
        // Probably not authorized
        // So force close
        exit(-1)
    }
    
    
    func onNetworkAvailable() {
        DispatchQueue.main.async {
            if !self.networkAuthHandler.isAuthenticated {
                let token = self.cryptoHelper.getPermanentTokenOnKeyChain()
                
                if token == nil {return}
                
                self.networkAuthHandler.requestToken(permanentToken: token!)
            }
        }
    }
    
    func onNetworkNotAvailable() {
        
    }
    
    func onFilesData(files: [VaultFileSerializable]) {
        for file in files {
            let vaultFile = self.vaultFileRepository.createVaultFileInstanceUniserted()
            
            let id = UUID(uuidString: file.fileClientId)
            
            vaultFile.id = id
            vaultFile.isInSync = true
            vaultFile.key = file.key
            vaultFile.iv = file.iv
            vaultFile.fileExtension = file.fileExtension
            vaultFile.name = file.name
            vaultFile.size = file.size
            
            let fileName = UUID().uuidString + ".enc"
            let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = dir.appendingPathComponent(fileName)
            
            
            vaultFile.path = fileURL
            
            self.vaultFileRepository.saveVaultFile(vaultFile: vaultFile)
            
            // Wrapper for the task
            var wrapper = VaultFileWrapper()
            wrapper.file = vaultFile
            wrapper.obs = MutableObservable<Float>(0)
            wrapper.task = TaskName.Download
                
            // Add to tasks list
            self.tasks[id!] = wrapper
            
            self.tableView.reloadData()
            self.networkFileHandler.getFile(fileID: file.fileClientId, destinationURL: fileURL, fileName: fileName, wrapper: wrapper)
        }
    }
    
    func onFileDownloaded(path: String) {
        
    }
    
    func onFileUploaded() {
        
    }
}
