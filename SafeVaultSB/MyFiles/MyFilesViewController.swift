//
//  MyFilesViewController.swift
//  SafeVaultSB
//
//  Created by Tiago Lima on 04/07/2020.
//  Copyright © 2020 Tiago Lima. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices
import CoreData
import CommonCrypto

extension MyFilesViewController: UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else {return}
        
        if searchText.count > 0 {
            searchFetch(text: searchText)
            self.isSearchMode = true
        } else if self.isSearchMode {
            normalFetch()
            self.isSearchMode = false
        }
    }
    
    private func searchFetch(text: String) {
        let predicate = NSPredicate(format: "name CONTAINS %@", text)
        fetchedResultsController.fetchRequest.predicate = predicate
        reFetch()
    }
    
    private func normalFetch() {
        let nameSort = NSSortDescriptor(key: "name", ascending: true)
        let predicate = NSPredicate(value: true)
        fetchedResultsController.fetchRequest.predicate = predicate
        fetchedResultsController.fetchRequest.sortDescriptors = [nameSort]
        reFetch()
    }
    
    private func reFetch() {
        do {
            try self.fetchedResultsController.performFetch()
            tableView.reloadData()
        } catch let error as NSError {
            print("Error: \(error.localizedDescription)")
        }
    }
    
    private func initializeSearchController() {
        self.searchController = UISearchController(searchResultsController:  nil)
               
        self.searchController.searchResultsUpdater = self
        self.searchController.delegate = self
        self.searchController.searchBar.delegate = self
        self.searchController.searchBar.placeholder = "Search files..."
        
        
        self.navigationItem.hidesSearchBarWhenScrolling = true
        self.navigationItem.searchController = searchController
        self.definesPresentationContext = true
    }
    
    func initialize() {
        let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
                      
        self.vaultFileRepository = appDelegate.vaultFileRepository
        self.cryptoHelper = appDelegate.cryptoHelper
        
        self.networkStatusHelper.delegate = self
        self.biometricsHelper.alertHelper = self.alertHelper
        self.networkAuthHandler.delegate = self
        self.networkFileHandler.delegate = self
        
        self.networkStatusHelper.initializeNetworkMonitor()
        self.initializeSearchController()
        
        self.syncData()
        
        // Remove separators
        self.tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        
        self.fetchedResultsController = vaultFileRepository.getFetchedResultsController(tableController: self)
    }
    
    private func syncData() {
        let isSyncNeeded = UserDefaults.standard.value(forKey: "syncNeeded") as? Bool ?? false
        
        if isSyncNeeded {
            self.networkFileHandler.getFileData()
        }
    }
    
    @IBAction func onAddPressed(_ sender: UIBarButtonItem) {
      
        if self.tableView.isEditing {
            self.handleDeleteItems()
        } else {
            self.showFilePicker()
        }
        
    }
    
    // Delete all selected files
    private func handleDeleteItems() {
        let indexPaths = self.tableView.indexPathsForSelectedRows
        
        if indexPaths == nil {return}
        
        var files: [VaultFile] = []
        
        for indexPath in indexPaths! {
            let file = self.fetchedResultsController?.object(at: indexPath)
            
            if file == nil {continue}
            
            files.append(file!)
        }
        
        self.tableView.setEditing(false, animated: true)
        
        
        let fileManager = FileManager()
            
        for file in files {
            DispatchQueue.global(qos: .background).async {
                do {
                    try fileManager.removeItem(at: file.path!)
                } catch {
                    print("Error: \(error)")
                }
            }
                
            self.vaultFileRepository.removeFile(vaultFile: file)
                
        }
        
    }
    
}
