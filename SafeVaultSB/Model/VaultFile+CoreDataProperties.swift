//
//  VaultFile+CoreDataProperties.swift
//  
//
//  Created by Tiago Lima on 06/07/2020.
//
//

import Foundation
import CoreData


extension VaultFile {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<VaultFile> {
        return NSFetchRequest<VaultFile>(entityName: "VaultFile")
    }

    @NSManaged public var fileExtension: String?
    @NSManaged public var id: UUID?
    @NSManaged public var key: String?
    @NSManaged public var name: String?
    @NSManaged public var path: URL?
    @NSManaged public var size: Int64

}
