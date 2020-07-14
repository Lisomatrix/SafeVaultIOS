//
//  VaultFileExtension.swift
//  SafeVaultSB
//
//  Created by Tiago Lima on 14/07/2020.
//  Copyright © 2020 Tiago Lima. All rights reserved.
//

import Foundation

extension VaultFile {
    // When a new version/build appears I have to rebuild the URL
    // Since the sandbox UUID might have changed
    func constructNewURL() {
        // Construct new file URL
        let fileName = self.path!.lastPathComponent
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = dir.appendingPathComponent(fileName)

        self.path = fileURL
    }
}
