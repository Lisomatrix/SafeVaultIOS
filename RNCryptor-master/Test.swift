//
//  Test.swift
//  RNCryptor
//
//  Created by Tiago Lima on 10/07/2020.
//  Copyright © 2020 Rob Napier. All rights reserved.
//

import Foundation

struct Test {
    
    func test() {
        let encryptor = RNCryptor.Encryptor(password: "")
        let iv = encryptor.getIV()
        
    }
}
