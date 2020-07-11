//
//  ClearHelper.swift
//  SafeVaultSB
//
//  Created by Tiago Lima on 11/07/2020.
//  Copyright © 2020 Tiago Lima. All rights reserved.
//

import Foundation
import UIKit

struct ClearHelper {
    
    // Clear all previous data
    func clearData() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        // Delete Core Data
        appDelegate.accountRepository.deletePreviousAccounts()
        appDelegate.vaultFileRepository.deletePreviousFiles()
        appDelegate.saveContext()
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
