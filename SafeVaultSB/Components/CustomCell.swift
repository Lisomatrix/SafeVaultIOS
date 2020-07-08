	//
//  CustomCell.swift
//  SafeVaultSB
//
//  Created by Tiago Lima on 03/07/2020.
//  Copyright © 2020 Tiago Lima. All rights reserved.
//

import Foundation
import UIKit
import Observable
    
class CustomCell: UITableViewCell {
    
    var fileName: String?
    var fileSize: String?
    
    var objectID: UUID?
    
    var disposable: Disposable?
    var taskName: TaskName?
    var isWorking: Bool = false
    
    @IBOutlet weak var FileNameView: UILabel!
    @IBOutlet weak var FileSizeView: UILabel!
    @IBOutlet weak var FileProgressView: UIProgressView!
    @IBOutlet weak var TaskNameView: UILabel!
    
    @IBOutlet weak var ShadowContainer: UIView!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
      
        //setCellShadow(cell: ShadowContainer)
        self.setStyle()
        
        if let fileName = fileName {
            FileNameView.text = fileName
        }
        
        if let fileSize = fileSize {
            FileSizeView.text = fileSize
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setStyle() {
        let isDarkTheme = traitCollection.userInterfaceStyle == .dark
        
        // Container
        self.ShadowContainer.layer.cornerRadius = 4
        self.ShadowContainer.clipsToBounds = false
        
        self.ShadowContainer.layer.shadowColor = cellShadowColor.cgColor
        self.ShadowContainer.layer.shadowOpacity = 1;
        self.ShadowContainer.layer.shadowRadius = 4;
        self.ShadowContainer.layer.shadowOffset = CGSize(width: 0.0, height: 0.0);
        
        if isDarkTheme {
            self.ShadowContainer.backgroundColor = darkColor
            self.FileNameView.textColor = UIColor.white
            self.FileSizeView.textColor = greyWhite
            self.TaskNameView.textColor = greyWhite
            
            let selectedBackground = UIView()
            selectedBackground.backgroundColor = UIColor.clear
            self.selectedBackgroundView = selectedBackground
        } else {
            self.TaskNameView.textColor = grey
            self.FileSizeView.textColor = grey
            self.FileNameView.textColor = UIColor.black
            self.ShadowContainer.backgroundColor = UIColor.white
            self.selectionStyle = .gray
        }
    }
}
