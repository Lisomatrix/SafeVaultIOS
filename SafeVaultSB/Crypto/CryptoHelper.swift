//
//  CryptoHelper.swift
//  SafeVaultSB
//
//  Created by Tiago Lima on 04/07/2020.
//  Copyright © 2020 Tiago Lima. All rights reserved.
//

import BiometricAuthentication
import Foundation
import MobileCoreServices
import CommonCrypto
import LocalAuthentication
import RNCryptor

class CryptoHelper {
    
    // Compare given hash with the one saved in KeyChain
    func checkKeyChainPassword(accountID: String, hashedPassword: String) -> Bool {
        do {
            let storedPasswordHash = try KeychainPasswordItem(accountID).readPassword()
            
            return hashedPassword == storedPasswordHash
        } catch {
            return false
        }
    }
    
    // Save hash on KeyChain
    func saveOnKeyChain(accountId: String, password: String) {
        do {
            // Hashing is never to much
            try KeychainPasswordItem(accountId).savePassword(password.sha512())
        } catch {
            print("Error on saving password on keychain: ", error)
        }
    }
    
    func saveTokenOnKeyChain(token: String) {
        do {
            try KeychainPasswordItem("token").savePassword(token)
        } catch {
            print("Error on saving token on keychain: ", error)
        }
    }
    
    func getTokenOnKeyChain() -> String? {
        do {
            return try KeychainPasswordItem("token").readPassword()
        } catch {
            print("Error on getting token from keychain: ", error)
            return nil
        }
    }
    
    func savePermanentTokenOnKeyChain(token: String) {
        do {
            try KeychainPasswordItem("permanentToken").savePassword(token)
        } catch {
            print("Error on saving token on keychain: ", error)
        }
    }
    
    func getPermanentTokenOnKeyChain() -> String? {
        do {
            return try KeychainPasswordItem("permanentToken").readPassword()
        } catch {
            print("Error on getting token from keychain: ", error)
            return nil
        }
    }
    
    // Had to fork RNCryptor in order to get IV
    func encryptFile(inputUri: URL, outputUri: URL, key: String, wrapper: VaultFileWrapper?) -> Data {
        // Initialize encryptor
        // This will generate the IV for us and keep it in the first file bytes
        let encryptor = RNCryptor.Encryptor(password: key)
        
        let iv = encryptor.getIV()
        
        // Create buffer
        let bufferSize = 4096
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        
        // Just to get percentages
        var totalDataRead = 0
        let fileSize = self.getFileSize(uri: inputUri)
        var lastPercentage: Float = 0
        
        // Create streams
        let inputStream = InputStream(url: inputUri)!
        let outputStream = OutputStream(url: outputUri, append: false)!
            
        // Open Streams
        inputStream.open()
        outputStream.open()
            
        // Read first chunk
        var bytesRead = inputStream.read(&buffer, maxLength: bufferSize)
        totalDataRead += bytesRead
            
        // Keep Data object size
        var size = 0
            
        // While there are bytes read
        while bytesRead > 0 {
                
            // Rly hope that a copy is not being made with Data object
            // Encrypt chunk
            var data = encryptor.update(withData: Data(buffer))
            size = data.count
                
                
            // I can't find any not deprecated alternative
            // The docs are even more confusing
            // Write chunck to new file
            data.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>) -> Void in
                outputStream.write(bytes, maxLength: size)
            }
                
            // Keep the cycle going
            bytesRead = inputStream.read(&buffer, maxLength: bufferSize)
            totalDataRead += bytesRead
            
            if wrapper != nil {
                let percentage = Float(totalDataRead) / Float(fileSize) * 100.0
                // Reduce the amount of updates
                // So instead of updating from 0.0001 to 0.0002
                // Only update if it passed from 0.1 to 0.2
                if percentage.rounded() > lastPercentage || percentage.rounded() == 100.0 {
                    lastPercentage = percentage.rounded()
                    wrapper?.obs?.wrappedValue = percentage / 100
                }
            }
        }
            
        // Clean the encryptor and write the last chunk
        // The last chunk will have the file Hmac that will be useless for us
        var result = encryptor.finalData()
        size = result.count
            
        
        // I can't find any not deprecated alternative
        // The docs are even more confusing
        result.withUnsafeMutableBytes({ (bytes: UnsafeMutablePointer<UInt8>) -> Void in
            outputStream.write(bytes, maxLength: size)
        })
            
        // Close streams
        inputStream.close()
        outputStream.close()
        
        return iv
    }
    
    func decryptFile(inputUri: URL, outputUri: URL, key: String, wrapper: VaultFileWrapper?) {
        // Initialize encryptor
        // This will generate the IV for us and keep it in the first file bytes
        let decryptor = RNCryptor.Decryptor(password: key)
           
        // Create buffer
        let bufferSize = 4096
        var buffer = [UInt8](repeating: 0, count: bufferSize)
           
        // Just to get percentages
        var totalDataRead = 0
        let fileSize = self.getFileSize(uri: inputUri)
        var lastPercentage: Float = 0
        
        // Create file
        FileManager.default.createFile(atPath: outputUri.path, contents: nil, attributes: nil)
        
        // Create streams
        let inputStream = InputStream(url: inputUri)!
        let outputStream = OutputStream(url: outputUri, append: false)!
               
        // Open Streams
        inputStream.open()
        outputStream.open()
               
        // Read first chunk
        var bytesRead = inputStream.read(&buffer, maxLength: bufferSize)
        totalDataRead += bytesRead
        
        // Keep Data object size
        var size = 0
        
        
        do {
            // While there are bytes read
            while bytesRead > 0 {
                       
                // Rly hope that a copy is not being made with Data object
                // Dencrypt chunk
                var data = try decryptor.update(withData: Data(buffer))
                size = data.count
                       
                
                // I can't find any not deprecated alternative
                // The docs are even more confusing
                // Write chunk to new file
                data.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>) -> Void in
                    outputStream.write(bytes, maxLength: size)
                }
                       
                // Keep the cycle going
                bytesRead = inputStream.read(&buffer, maxLength: bufferSize)
                totalDataRead += bytesRead
                
                if wrapper != nil {
                    let percentage = Float(totalDataRead) / Float(fileSize) * 100.0
                    // Reduce the amount of updates
                    // So instead of updating from 0.0001 to 0.0002
                    // Only update if it passed from 0.1 to 0.2
                    if percentage.rounded() > lastPercentage || percentage.rounded() == 100.0 {
                        lastPercentage = percentage.rounded()
                        wrapper?.obs?.wrappedValue = percentage / 100
                    }
                }
            }
                   
            // Clean the decryptor and write the last chunk
            // The last chunk will have the file Hmac that will be useless for us
            var result = try decryptor.finalData()
            size = result.count
            
            // I can't find any not deprecated alternative
            // The docs are even more confusing
            result.withUnsafeMutableBytes({ (bytes: UnsafeMutablePointer<UInt8>) -> Void in
                outputStream.write(bytes, maxLength: size)
            })
        } catch {
            print("Error: \(error)")
        }
               
        // Close streams
        inputStream.close()
        outputStream.close()
    }
    
    func getFileSize(uri: URL) -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: uri.path)
            return attributes[FileAttributeKey.size] as! Int64
        } catch {
            print("Error: \(error)")
            return 0
        }
    }
}
