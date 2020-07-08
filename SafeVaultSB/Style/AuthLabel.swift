//
//  AuthLabel.swift
//  SafeVaultSB
//
//  Created by Tiago Lima on 07/07/2020.
//  Copyright © 2020 Tiago Lima. All rights reserved.
//

import Foundation
import UIKit

class AuthLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setStyle()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setStyle()
    }

    private func setStyle() {
        let isDarkTheme = traitCollection.userInterfaceStyle == .dark
        
        if isDarkTheme {
            self.textColor = UIColor.black
        } else {
            self.textColor = UIColor.white
        }
    }
}
