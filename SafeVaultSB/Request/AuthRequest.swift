//
//  AuthRequest.swift
//  SafeVaultSB
//
//  Created by Tiago Lima on 10/07/2020.
//  Copyright © 2020 Tiago Lima. All rights reserved.
//

import Foundation

struct AuthRequest: Encodable, Decodable {
    let username: String
    let password: String
}
