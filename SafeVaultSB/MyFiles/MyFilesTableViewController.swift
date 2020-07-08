//
//  MyFIlesViewController.swift
//  SafeVaultSB
//
//  Created by Tiago Lima on 03/07/2020.
//  Copyright © 2020 Tiago Lima. All rights reserved.
//

import UIKit
import CoreData
import MobileCoreServices
import Observable

class MyFilesViewController: UITableViewController, NSFetchedResultsControllerDelegate, BiometricsHelperDelegate {
    
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    @IBOutlet var myFilesTable: UITableView!
    
    var searchController : UISearchController!
    
    // helper to format file size
    private let formatter = ByteCountFormatter()
    
    var vaultFileRepository: VaultFileRepository!
    var cryptoHelper: CryptoHelper!
    
    var fetchedResultsController: NSFetchedResultsController<VaultFile>!
    
    var isSearchMode: Bool = false
    
    var selectedVaultFile: VaultFile? = nil
    
    var tasksCounter = 0
    
    var tasks: Dictionary<UUID, VaultFileWrapper> = [:]
    
    let alertHelper = AlertHelper()
    let biometricsHelper = BiometricsHelper()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialize()
        self.alertHelper.delegate = self
        self.biometricsHelper.biometricAuthentication(reason: "Log in into your account")
        self.biometricsHelper.alertHelper = self.alertHelper
        
        self.navigationItem.rightBarButtonItems?.append(self.editButtonItem)
        //self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        
        
        self.tableView.allowsMultipleSelectionDuringEditing = true
        self.tableView.allowsSelection = true
    }
    
    // Change add btn icon
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing {
            if #available(iOS 13.0, *) {
                self.addButton.image = UIImage(systemName: "trash")
            } else {
                // Fallback on earlier versions
                self.addButton.title = "Delete"
            }
        } else {
            if #available(iOS 13.0, *) {
                self.addButton.image = UIImage(systemName: "plus.circle")
            } else {
                // Fallback on earlier versions
                self.addButton.title = "New"
            }
        }
        
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Notify table view that data will change
        tableView.beginUpdates()
    }
    
    func unauthorized() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func authorized() {
        // do nothing
    }
    
    // Compare sections and update accordingly
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        case .move:
            break
        case .update:
            break
            
        default:
            break
        }
    }
    
    // Compare elements (in this case files) and update accordingly
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
            
        default:
            break
        }
    }
    
    // End of changes notify and draw
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections!.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController.sections else {
            fatalError("No sections in fetchedResultsController")
        }
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }

    
    // Set the spacing between sections
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10.0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyFileCell", for: indexPath) as! CustomCell
        
        // Set up the cell
        guard let file = self.fetchedResultsController?.object(at: indexPath) else {
            fatalError("Attempt to configure cell without a managed object")
        }
       
        // If previous holding file is not equal then
        // stop the observable and update properties
        if cell.objectID != file.id {
            cell.disposable?.dispose()
            cell.objectID = file.id
            cell.FileProgressView.setProgress(0, animated: false)
            cell.FileProgressView.isHidden = true
            cell.TaskNameView.text = ""
        }
        
        // This is hacky way to get encryption progress
        // So we have a wrapper that has the file object and a observable
        let wrapper = getObservable(objectID: file.id!)
        
        // We check if a task exists
        if wrapper != nil {
            // Set working task name
            cell.TaskNameView.text = wrapper?.task == TaskName.Encrypt ? "Encrypting" : "Decrypting"
            // Flag in order to not allow to be selected to decrypt
            cell.isWorking = true
            
            // if so show the progress bar
            cell.FileProgressView.isHidden = false
            // and listen for progress change
            //wrapper?.disposable
            cell.disposable = wrapper!.obs?.observe { newValue, oldValue in
                
                // We have to update the progress bar on main thread
                DispatchQueue.main.async {
                    cell.FileProgressView.setProgress(newValue, animated: true)
                }
                
                // When it reaches 100% hide the progress bar
                if newValue == 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
                        cell.FileProgressView.isHidden = true
                        cell.FileProgressView.setProgress(0, animated: false)
                        cell.TaskNameView.text = ""
                        cell.isWorking = false
                    }
                    // And cleanup this task
                    self.tasks.removeValue(forKey: wrapper!.file!.id!)
                    wrapper?.disposable?.dispose()
                }
            }
            
        }
        
        // Update row data
        cell.fileName = file.name
        cell.fileSize = formatter.string(fromByteCount: file.size)

        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70;
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = self.tableView.cellForRow(at: indexPath) as! CustomCell
        
        if self.tableView.isEditing {
            return
        }
        
        guard let file = self.fetchedResultsController?.object(at: indexPath) else {
            fatalError("Cell without managed item pressed")
        }
        
        if cell.isWorking {
            self.alertHelper.showAlert(title: "Can't decrypt yet", message: "File is still encrypting")
            return
        }
        
        // Check if file still exists
        if FileManager.default.fileExists(atPath: file.path!.path) {
            self.selectedVaultFile = file
            self.showFolderPicker()
        } else {
            self.vaultFileRepository.removeFile(vaultFile: file)
            self.alertHelper.showErrorAlert(message: "Selected file no longer exists")
        }
        
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        let cell = self.tableView.cellForRow(at: indexPath) as? CustomCell
        
        if cell == nil {
            return false
        }
        
        return !cell!.isWorking
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            print("Delete")
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .none {
            print("edit")
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    // Get the observable from the task dictionary
    private func getObservable(objectID: UUID) -> VaultFileWrapper? {
        for task in self.tasks {
            if task.key == objectID {
                return task.value
            }
        }
        
        return nil
    }
}
