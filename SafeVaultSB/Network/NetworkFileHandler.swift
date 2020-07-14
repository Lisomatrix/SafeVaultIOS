//
//  NetworkFileHandler.swift
//  SafeVaultSB
//
//  Created by Tiago Lima on 10/07/2020.
//  Copyright © 2020 Tiago Lima. All rights reserved.
//

import Foundation
import Alamofire
import CryptoSwift

protocol NetworkFileDelegate {
    func onFilesData(files: [VaultFileSerializable])
    func onFileDownloaded(path: String)
    func onFileUploaded();
}

class NetworkFileHandler {
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let baseURL = "http://192.168.1.12:8080/file/"
    //let baseURL = "http://localhost:8080/file/"
    
    var delegate: NetworkFileDelegate?
    
    var fileID: String?
    
    func getFileData() {
        let token = self.appDelegate.cryptoHelper.getTokenOnKeyChain()
        
        if token == nil {return}
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token ?? "")",
            "Content-Type": "application/json"
        ]
        
        AF.request(
            baseURL + "files",
            method: .get,
            headers: headers
        ).response { response in
            
            if response.data == nil || response.error != nil {
                if response.error != nil {
                    print("Error: \(String(describing: response.error))")
                }
                return
            }
            
            let decoder = JSONDecoder()
            
            do {
                var data = try decoder.decode(Array<VaultFileSerializable>.self, from: response.data!)
                
                for i in 0..<data.count {
                    data[i] = self.decryptFile(&data[i])
                }
                
                self.delegate?.onFilesData(files: data)
            } catch {
                print("error: \(error)")
            }
        }
    }
    
    private func decryptFile(_ receivedFile: inout VaultFileSerializable) -> VaultFileSerializable {
        
        guard let password = self.appDelegate.cryptoHelper.getKeyChainPassword() else {
            return receivedFile
        }
        
        do {
            let subIV = receivedFile.iv[0...11]
            let subKey = password[0...31]
            let decryptor = try ChaCha20(key: subKey, iv: subIV)
         
            // Base64 String to array
            let nameInt8Array = [UInt8](Data(base64Encoded: receivedFile.name)!)
            let extensionInt8Array = [UInt8](Data(base64Encoded: receivedFile.fileExtension)!)
            let keyInt8Array = [UInt8](Data(base64Encoded: receivedFile.key)!)

            // Decrypt data
            let fileName = Data(try decryptor.decrypt(nameInt8Array))
            let fileExtension = Data(try decryptor.decrypt(extensionInt8Array))
            let key = Data(try decryptor.decrypt(keyInt8Array))
                      
            // To String
            receivedFile.name = String(data: fileName, encoding: .utf8)!
            receivedFile.fileExtension = String(data: fileExtension, encoding: .utf8)!
            receivedFile.key = String(data: key, encoding: .utf8)!
            
        } catch {
            print("Error: \(error)")
        }
        
        return receivedFile
    }
    
    func getFile(fileID: String, destinationURL: URL, fileName: String, wrapper: VaultFileWrapper? = nil) {
        let token = self.appDelegate.cryptoHelper.getTokenOnKeyChain()
              
        if token == nil {return}
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token ?? "")",
        ]
        
        let destination: DownloadRequest.Destination = { _, _ in
            let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentURL.appendingPathComponent(fileName)
            
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        AF.download(baseURL + fileID, headers: headers, to: destination)
            .downloadProgress { progress in
            wrapper?.obs?.wrappedValue = Float(progress.fractionCompleted)
            
        }.response { response in
            // In case of error attempt do download it later
            if response.error != nil {
                // Works bc a class is passed by ref
                wrapper?.remove = true
                wrapper?.obs?.wrappedValue = 1
            }
        }
    }
    
    func requestFileUpload(vaultFile: VaultFile, wrapper: VaultFileWrapper) {
        
        let token = self.appDelegate.cryptoHelper.getTokenOnKeyChain()
        
        if token == nil {return}
        
        guard let password = self.appDelegate.cryptoHelper.getKeyChainPassword() else {
            return
        }
    
        do {
            
            let subIV = vaultFile.iv![0...11]
            let subKey = password[0...31]
            let encryptor = try ChaCha20(key: subKey, iv: subIV)
             
            let fileNameEnc = try encryptor.encrypt([UInt8](vaultFile.name!.utf8))
            let fileExtensionEnc = try encryptor.encrypt([UInt8](vaultFile.fileExtension!.utf8))
            let keyEnc = try encryptor.encrypt([UInt8](vaultFile.key!.utf8))
            
            let uploadFileRequest = FileUploadRequest(
                    fileClientId: vaultFile.id!.uuidString,
                    name: fileNameEnc.toBase64()!,
                    fileExtension: fileExtensionEnc.toBase64()!,
                    size: vaultFile.size,
                    iv: vaultFile.iv!,
                    key: keyEnc.toBase64()!
            )
                
            self.fileID = vaultFile.id!.uuidString.replacingOccurrences(of: "-", with: "")
                
            let headers: HTTPHeaders = [
                "Authorization": "Bearer \(token ?? "")",
                "Content-Type": "application/json"
            ]
            
            AF.request(
                baseURL + "upload",
                method: .post,
                parameters: uploadFileRequest,
                encoder: JSONParameterEncoder.default,
                headers: headers
            ).response { response in self.handleFileRequest(response: response, wrapper: wrapper)}
            
        } catch {
            print("Error: \(error)")
            return
        }
    }
    
    private func handleFileRequest(response: AFDataResponse<Data?>, wrapper: VaultFileWrapper) {
        
        if response.data == nil || response.error != nil {
            if response.error != nil {
                print("Error: \(String(describing: response.error))")
            }
            return
        }
        
        let fileServerID = String(data: response.data!, encoding: .utf8)
        self.uploadFile(fileServerID: fileServerID!, wrapper: wrapper)
        
    }
    
    private func uploadFile(fileServerID: String, wrapper: VaultFileWrapper) {
        
        let token = self.appDelegate.cryptoHelper.getTokenOnKeyChain()
        
        if token == nil {return}
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token ?? "")",
            "Content-type": "multipart/form-data",
        ]
        
        let url =  baseURL + fileServerID + "/upload"
        
        AF.upload(multipartFormData: { multiForm in
            multiForm.append(wrapper.file!.path!, withName: "file")
        }, to: url, headers: headers)
        .uploadProgress { progress in
            wrapper.obs?.wrappedValue = Float(progress.fractionCompleted)
        }
        .response { response in
            // in case of error then attempt to sync another time
            if response.error != nil {
                print("Error: \(response.error!)")
                wrapper.obs?.wrappedValue = 1
                wrapper.file?.isInSync = false
            } else {
                wrapper.file?.isInSync = true
            }
            
            if wrapper.file != nil {
                self.appDelegate.vaultFileRepository.saveVaultFile(vaultFile: wrapper.file!)
            }
        }
    }
}
