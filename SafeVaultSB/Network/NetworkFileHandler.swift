//
//  NetworkFileHandler.swift
//  SafeVaultSB
//
//  Created by Tiago Lima on 10/07/2020.
//  Copyright © 2020 Tiago Lima. All rights reserved.
//

import Foundation
import Alamofire

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
                let data = try decoder.decode(Array<VaultFileSerializable>.self, from: response.data!)
                self.delegate?.onFilesData(files: data)
            } catch {
                print("error: \(error)")
            }
        }
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
            print(response)
        }
    }
    
    func requestFileUpload(vaultFile: VaultFile, fileURL: URL, wrapper: VaultFileWrapper? = nil) {
        
        let token = self.appDelegate.cryptoHelper.getTokenOnKeyChain()
        
        if token == nil {return}
        
        let uploadFileRequest = FileUploadRequest(
            fileClientId: vaultFile.id!.uuidString,
            name: vaultFile.name!,
            fileExtension: vaultFile.fileExtension!,
            size: vaultFile.size,
            iv: vaultFile.iv!,
            key: vaultFile.key!
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
        ).response { response in self.handleFileRequest(response: response, url: fileURL, wrapper: wrapper)}
    }
    
    private func handleFileRequest(response: AFDataResponse<Data?>, url: URL, wrapper: VaultFileWrapper?) {
        
        if response.data == nil || response.error != nil {
            if response.error != nil {
                print("Error: \(String(describing: response.error))")
            }
            return
        }
        
        let fileServerID = String(data: response.data!, encoding: .utf8)
        self.uploadFile(fileServerID: fileServerID!, fileURL: url, wrapper: wrapper)
        
    }
    
    private func uploadFile(fileServerID: String, fileURL: URL, wrapper: VaultFileWrapper?) {
        
        let token = self.appDelegate.cryptoHelper.getTokenOnKeyChain()
        
        if token == nil {return}
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token ?? "")",
            "Content-type": "multipart/form-data",
        ]
        
        let url =  baseURL + fileServerID + "/upload"
                
        AF.upload(multipartFormData: { multiForm in
            multiForm.append(fileURL, withName: "file")
        }, to: url, headers: headers)
        .uploadProgress { progress in
            wrapper?.obs?.wrappedValue = Float(progress.fractionCompleted)
        }
        .response { response in }
    }
}
