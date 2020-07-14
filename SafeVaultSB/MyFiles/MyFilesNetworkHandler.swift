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
    
    func onAuthenticated(_ token: String) {
        self.cryptoHelper.saveTokenOnKeyChain(token: token)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.isServerAuthenticated = true
        
        DispatchQueue.global(qos: .background).async {
            // This will trigger a sync
            self.networkFileHandler.getFileData()
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
    
    func toVaultFile(_ file: VaultFileSerializable) -> VaultFile {
        let vaultFile = self.vaultFileRepository.createVaultFileInstanceUniserted()
        
        let id = UUID(uuidString: file.fileClientId)
        
        vaultFile.id = id
        vaultFile.isInSync = true
        vaultFile.key = file.key
        vaultFile.iv = file.iv
        vaultFile.fileExtension = file.fileExtension
        vaultFile.name = file.name
        vaultFile.size = file.size
        
        return vaultFile
    }
    
    func onFilesData(files: [VaultFileSerializable]) {
        self.checkFilesNeedingSync(serverFiles: files)
    }
    
    
    func checkFilesToDownload(_ serverFiles: [VaultFileSerializable]) -> [VaultFileSerializable] {
        let files = self.vaultFileRepository.getVaultFiles()
        
        // If we don't have files then get them all
        if files == nil {return serverFiles}
        
        var fileToDownload: [VaultFileSerializable] = []
        
        for serverFile in serverFiles {
            var found = false
            for file in files! {
                if serverFile.fileClientId == file.id!.uuidString {
                    found = true
                    break
                }
            }
            
            if !found {
                fileToDownload.append(serverFile)
            }
        }
        
        return fileToDownload
    }
    
    func checkFilesNeedingSync(serverFiles: [VaultFileSerializable]) {
        
        // files needing upload
        let unsycedFiles = self.vaultFileRepository.getVaultFileNotSynced()
        
        if unsycedFiles != nil {
            // Upload files
            for file in unsycedFiles! {
                self.prepareFileUpload(file)
            }
        }
        
        let filesNeedingSync = self.checkFilesToDownload(serverFiles)
        
        print("")
        print("count: \(filesNeedingSync.count)")
        print("")
        var c = 1
        // Download files
        for file in filesNeedingSync {
            self.prepareFileDownload(file)
            print("count: \(c)")
            c += 1
        }
        
        self.tableView.reloadData()
    }
    
    private func prepareFileDownload(_ file: VaultFileSerializable) {
        let vaultFile = self.toVaultFile(file)
        
        let fileName = UUID().uuidString + ".enc"
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = dir.appendingPathComponent(fileName)
        
        vaultFile.path = fileURL
        
        // Wrapper for the task
        let wrapper = VaultFileWrapper()
        wrapper.file = vaultFile
        wrapper.obs = MutableObservable<Float>(0)
        wrapper.task = TaskName.Download
            
        // Add to tasks list
        self.tasks[vaultFile.id!] = wrapper
        
        self.vaultFileRepository.saveVaultFile(vaultFile: vaultFile)
        
        //self.tableView.reloadData()
        self.networkFileHandler.getFile(fileID: file.fileClientId, destinationURL: fileURL, fileName: fileName, wrapper: wrapper)
    }
    
    func prepareFileUpload(_ file: VaultFile) {
        // Wrapper for the task
        let wrapper = VaultFileWrapper()
        wrapper.file = file
        wrapper.obs = MutableObservable<Float>(0)
        wrapper.task = TaskName.Upload
        
        file.constructNewURL()
        
        self.vaultFileRepository.saveVaultFile(vaultFile: file)

        // Add to tasks list
        self.tasks[wrapper.file!.id!] = wrapper
        self.networkFileHandler.requestFileUpload(vaultFile: file, wrapper: wrapper)
    }
    
    func onFileDownloaded(path: String) {
        
    }
    
    func onFileUploaded() {
        
    }
}
