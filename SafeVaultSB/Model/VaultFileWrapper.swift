//
//  VaultFileExtensions.swift
//  SafeVaultSB
//
//  Created by Tiago Lima on 05/07/2020.
//  Copyright © 2020 Tiago Lima. All rights reserved.
//

import Foundation
import Observable
import CoreData

enum TaskName {
    case Encrypt
    case Decrypt
    case Download
    case Upload
}

class VaultFileWrapper {
    var file: VaultFile?
    var obs: MutableObservable<Float>?
    var disposable: Disposable?
    var task: TaskName?
    var remove: Bool = false
}
