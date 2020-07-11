//
//  VaultFileRepository.swift
//  SafeVaultSB
//
//  Created by Tiago Lima on 04/07/2020.
//  Copyright © 2020 Tiago Lima. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class VaultFileRepository {
    
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    private let managedContext: NSManagedObjectContext
        
    private let entity: NSEntityDescription
    
    init() {
        managedContext = appDelegate.persistentContainer.viewContext
        entity = NSEntityDescription.entity(forEntityName: "VaultFile", in: managedContext)!
    }
    
    func getVaultFilesByName(name: String) -> [VaultFile]? {
        
        let fetchRequest =
          NSFetchRequest<VaultFile>(entityName: "VaultFile")
        
        fetchRequest.predicate = NSPredicate(format: "name LIKE %@", name)
        
        do {
            return try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            return nil
        }
    }
    
    func getVaultFileNotSynced() -> [VaultFile]? {
        let fetchRequest =
              NSFetchRequest<VaultFile>(entityName: "VaultFile")
        
        
        fetchRequest.predicate = NSPredicate(format: "isInSync = %@", false)
        do {
            return try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            return nil
        }
    }
    
    func getVaultFileByID(id: UUID, context: NSManagedObjectContext? = nil) -> VaultFile? {
        let fetchRequest =
              NSFetchRequest<VaultFile>(entityName: "VaultFile")
            
        
        fetchRequest.predicate = NSPredicate(format: "id LIKE %@", id as CVarArg)
        
        do {
            if context != nil {
                return try context?.fetch(fetchRequest)[0]
            } else {
                return try managedContext.fetch(fetchRequest)[0]
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            return nil
        }
    }
    
    func createVaultFileInstance() -> VaultFile {
        return VaultFile(context: managedContext)
    }
    
    func createVaultFileInstanceUniserted() -> VaultFile {
        return VaultFile(entity: entity, insertInto: nil)
    }
    
    func saveVaultFile(vaultFile: VaultFile) {
        if !vaultFile.isInserted {
            managedContext.insert(vaultFile)
        }
        
        appDelegate.saveContext()
    }
    
    func deletePreviousFiles() {

        let fetchRequest = NSFetchRequest<VaultFile>(entityName: "VaultFile")
        fetchRequest.returnsObjectsAsFaults = false

        do {
            let results = try managedContext.fetch(fetchRequest)
            for object in results {
                managedContext.delete(object)
            }
        } catch let error {
            print("Error deleting all files:", error)
        }
    }
    
    func removeFile(vaultFile: VaultFile) {
        managedContext.delete(vaultFile)
        appDelegate.saveContext()
    }
    
    func getFetchedResultsController(tableController: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<VaultFile>! {
        var fetchedResultsController: NSFetchedResultsController<VaultFile>!
        
        let fetchRequest =
            NSFetchRequest<VaultFile>(entityName: "VaultFile")
        
        // Sort list by name ASCENDING
        let nameSort = NSSortDescriptor(key: "name", ascending: true)
              
        fetchRequest.sortDescriptors = [nameSort]
        
        fetchedResultsController
            = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: managedContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
        
        fetchedResultsController.delegate = tableController
        
        do {
            // Fetch data
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Failed to initialize FetchedResultsController: \(error)")
        }
        
        return fetchedResultsController
    }
}
