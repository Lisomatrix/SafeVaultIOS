//
//  AccountRepository.swift
//  SafeVaultSB
//
//  Created by Tiago Lima on 04/07/2020.
//  Copyright © 2020 Tiago Lima. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class AccountRepository {
    
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    private let managedContext: NSManagedObjectContext
        
    private let entity: NSEntityDescription
    
    init() {
           managedContext = appDelegate.persistentContainer.viewContext
           entity = NSEntityDescription.entity(forEntityName: "Account", in: managedContext)!
    }
    
    func getAccount(accountID: String, password: String) -> Account? {
        let fetchRequest =
            NSFetchRequest<Account>(entityName: "Account")
        
        
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate
            = NSPredicate(format: "accountID == %@ AND password = %@", accountID, password)
        
        do {
            let accounts = try managedContext.fetch(fetchRequest)
            
            if accounts.count > 0 {
                return accounts[0]
            }
            
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
         return nil
    }
    
    /// Delete previous accounts from Core Data
    func deletePreviousAccounts() {
        
        let fetchRequest = NSFetchRequest<Account>(entityName: "Account")
        fetchRequest.returnsObjectsAsFaults = false

        do {
            let results = try managedContext.fetch(fetchRequest)
            for object in results {
                managedContext.delete(object)
            }
        } catch let error {
            print("Error deleting all accounts:", error)
        }
    }
    
    /// Create new account
    func createAccount(password: String) -> Account {
        let account = self.createAccountInstanceUniserted()
           
        account.accountID = String.randomString(length: 8)
        account.password = password.sha512()
           
        self.saveAccount(account: account)
           
        return account
    }
    
    func createAccountInstance() -> Account {
        return Account(context: managedContext)
    }
    
    func createAccountInstanceUniserted() -> Account {
        return Account(entity: entity, insertInto: nil)
    }
    
    func saveAccount(account: Account) {
        if !account.isInserted {
            managedContext.insert(account)
        }
        
        appDelegate.saveContext()
    }
    
    func getAccount() -> Account? {
        let fetchRequest =
            NSFetchRequest<Account>(entityName: "Account")
        
        fetchRequest.fetchLimit = 1
        
        do {
            let accounts = try managedContext.fetch(fetchRequest)
            
            if accounts.count > 0 {
                return accounts[0]
            }
            
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        return nil
    }
}
