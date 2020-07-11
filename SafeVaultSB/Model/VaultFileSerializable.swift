//
//  VaultFileSerializable.swift
//  SafeVaultSB
//
//  Created by Tiago Lima on 11/07/2020.
//  Copyright © 2020 Tiago Lima. All rights reserved.
//

import Foundation

struct VaultFileSerializable : Codable {
    let fileServerId: String
    let fileClientId: String
    let fileExtension: String
    let key: String
    let name: String
    let size: Int64
    let iv: String
}
