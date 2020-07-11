//
//  FileUploadRequest.swift
//  SafeVaultSB
//
//  Created by Tiago Lima on 10/07/2020.
//  Copyright © 2020 Tiago Lima. All rights reserved.
//

import Foundation

struct FileUploadRequest: Encodable {
    let fileClientId: String
    let name: String
    let fileExtension: String
    let size: Int64
    let iv: String
    let key: String
}
