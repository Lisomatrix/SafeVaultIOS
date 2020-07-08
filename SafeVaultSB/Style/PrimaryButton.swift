//
//  PrimaryButton.swift
//  SafeVaultSB
//
//  Created by Tiago Lima on 07/07/2020.
//  Copyright © 2020 Tiago Lima. All rights reserved.
//

import Foundation
import UIKit

class PrimaryButton: UIButton {
    
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
        
        self.layer.cornerRadius = 4
        self.clipsToBounds = false
           
        self.layer.shadowColor = shadowColor.cgColor
        self.layer.shadowOpacity = 1;
        self.layer.shadowRadius = 20;
        self.layer.shadowOffset = CGSize(width: 0.0, height: 6.0);
        
        if isDarkTheme {
            self.layer.backgroundColor = darkColor.cgColor
        }
    }
}
