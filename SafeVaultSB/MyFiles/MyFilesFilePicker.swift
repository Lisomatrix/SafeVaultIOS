//
//  MyFilesFilePicker.swift
//  SafeVaultSB
//
//  Created by Tiago Lima on 04/07/2020.
//  Copyright © 2020 Tiago Lima. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices
import CryptoKit
import CryptoSwift
import Observable

extension MyFilesViewController: UIDocumentPickerDelegate {
    
    func showFilePicker() {
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
        
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    func showFolderPicker() {
        let documentPicker = UIDocumentPickerViewController(documentTypes: [
            kUTTypeFolder as String], in: .open)
        
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selected = urls.first else {
            return
        }
        
        // Check if selected URL is a folder
        let isDirectory = (try? selected.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false

        // This code is CPU intensive and blocking
        // So I don't want it in UI Thread
        DispatchQueue.global(qos: .background).async {
            // Handle it accordingly
            if !isDirectory {
                self.handleFileSelected(selectedFile: selected)
            } else {
                self.handleFolderSelected(selectedFolder: selected)
            }
        }
    }
    
    private func handleFolderSelected(selectedFolder: URL) {
        if self.selectedVaultFile == nil {
            return
        }
        
        // Since I don't pretend to make the user wait for the file decrypt to end
        // I will keep a ref to the file here
        let vaultFile = self.selectedVaultFile!
        self.selectedVaultFile = nil
        
        // Create path with original file name
        var newFile = selectedFolder
        
        newFile.appendPathComponent("\(vaultFile.name!)")
        
        // Wrapper for the task
        var wrapper = VaultFileWrapper()
        wrapper.file = vaultFile
        wrapper.obs = MutableObservable<Float>(0)
        wrapper.task = TaskName.Decrypt
        
        // Add to tasks list
        self.tasks[wrapper.file!.id!] = wrapper
        
        // Reload the table so it will track the progress
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        
        self.cryptoHelper.decryptFile(inputUri: vaultFile.path!, outputUri: newFile, key: vaultFile.key!, wrapper: wrapper)
    }
    
    private func handleFileSelected(selectedFile: URL) {
        let vaultFile = self.vaultFileRepository.createVaultFileInstanceUniserted()
            
        vaultFile.name = selectedFile.lastPathComponent
        vaultFile.fileExtension = selectedFile.pathExtension
            
        vaultFile.size = self.cryptoHelper.getFileSize(uri: selectedFile)
        
        // Get new encrypted file path
        let newFile = "\(UUID().uuidString.replacingOccurrences(of: "-", with: "")).enc"
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = dir.appendingPathComponent(newFile)
            
        vaultFile.path = fileURL
        
        // Generate a String to be used as key
        // Inside encrypt method it will be changed by PBKDF2
        // In order to make it secure
        vaultFile.key = String.randomString(length: 30)
        vaultFile.id = UUID()
      
        // These "Tasks" are ways for udapting the UI about the encryption status
        
        // Wrapper for the task
        var wrapper = VaultFileWrapper()
        wrapper.file = vaultFile
        wrapper.obs = MutableObservable<Float>(0)
        wrapper.task = TaskName.Encrypt
        
        // Add to tasks list
        self.tasks[wrapper.file!.id!] = wrapper
        
        
        // Not sure if I rly need to do this
        // But atleast I avoid concurrency problems
        DispatchQueue.main.async {
            self.vaultFileRepository.saveVaultFile(vaultFile: vaultFile)
        }
       
        self.cryptoHelper.encryptFile(inputUri: selectedFile, outputUri: fileURL, key: vaultFile.key!, wrapper: wrapper)
        
        // Delete selected file
        do {
            try FileManager.default.removeItem(at: selectedFile)
        } catch {
            print("Error: \(error)")
        }
    }
}
