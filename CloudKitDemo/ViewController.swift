//
//  ViewController.swift
//  CloudKitDemo
//
//  Created by Jéssica Araujo on 19/10/20.
//  Copyright © 2020 academy. All rights reserved.
//

import UIKit
import CloudKit

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    let dataBase = CKContainer.default().privateCloudDatabase
    
    var notes = [CKRecord]()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(queryDatabase), for: .valueChanged)
        self.tableView.refreshControl = refreshControl
        queryDatabase()
    }
    
    @IBAction func onPlusTapped() {
        
        let alert = UIAlertController(title: "Type Something", message: "What would you like to save in a note?", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Type Note Here"
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let post = UIAlertAction(title: "Post", style: .default) { (_) in
            
            guard let text = alert.textFields?.first?.text else { return }
            self.saveToCloud(note: text)
        }
        
        alert.addAction(cancel)
        alert.addAction(post)
        
        present(alert, animated: true, completion: nil)
    }
    
    func saveToCloud(note:String) {
        
        let newNote = CKRecord(recordType: .init("Note"))
        newNote.setValue(note, forKey: "content")
        
        dataBase.save(newNote) { (record, error) in
            print(error)
            guard record != nil else { return }
            print("save record")
        }
    }
    
    @objc func queryDatabase() {
        
        let query = CKQuery(recordType: "Note", predicate: NSPredicate(value: true))
        
        dataBase.perform(query, inZoneWith: nil) { (records, _) in
            
            guard let records = records else { return }
            
            let sortedRecords = records.sorted(by: {$0.creationDate! > $1.creationDate! })
            
            self.notes = sortedRecords
            
            DispatchQueue.main.async {
                
                self.tableView.refreshControl?.endRefreshing()
                self.tableView.reloadData()
            }
        }
    }
}

extension ViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return notes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell()
        
        let note = notes[indexPath.row].value(forKey: "content") as! String
        
        cell.textLabel?.text = note
        return cell
    }
}
