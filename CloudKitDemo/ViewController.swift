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
        
        getCreatNoteAlert()
    }
    
    func saveToCloud(note:String) {
        
        let newNote = CKRecord(recordType: .init("Note"))
        newNote.setValue(note, forKey: "content")
        
        dataBase.save(newNote) { (record, error) in
            
            print("hello im trying")
            
            if error != nil {
                
                let alert = UIAlertController(title: "Eita", message: "Erro ao salvar.../n" + error!.localizedDescription, preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alert,animated: true, completion: nil)
            }
            
            guard record != nil else { return }
        }
    }
    
    @objc func queryDatabase() {
        
        let query = CKQuery(recordType: "Note", predicate: NSPredicate(value: true))
        
        dataBase.perform(query, inZoneWith: nil) { (records, error) in
            
            guard let records = records else { return }
            
            let sortedRecords = records.sorted(by: {$0.creationDate! > $1.creationDate!})
            
            self.notes = sortedRecords
            
            DispatchQueue.main.async {
                
                self.tableView.refreshControl?.endRefreshing()
                self.tableView.reloadData()
            }
        }
    }
    
    func getCreatNoteAlert(){
        
        let alert = UIAlertController(title: "Type Something", message: "What would you like to save in a note?", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Type Note Here"
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let post = UIAlertAction(title: "Post", style: .default) { (_) in
            
            guard let text = alert.textFields?.first?.text else { return }
            self.saveToCloud(note: text)
        }
        
        post.isEnabled = false
        
        //only enable the post action when the text field isnt nill
        NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: alert.textFields?.first, queue: .main) { (notification) in
            post.isEnabled = alert.textFields?.first?.text != ""
        }
        
        alert.addAction(cancel)
        alert.addAction(post)
        
        present(alert, animated: true, completion: nil)
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
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
    
    //Update
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        print(notes[indexPath.row])
        
        //get the note to edit
        let noteToEdit = notes[indexPath.row].value(forKey: "content") as! String
        
        let alert = UIAlertController(title: "Edit", message: "Edit note: ", preferredStyle: .alert)
        alert.addTextField()
        
        let textField = alert.textFields?.first
        textField?.text = noteToEdit
        
        let editButton = UIAlertAction(title: "Edit", style: .default){ (action) in
            
            let newNote = alert.textFields?.first?.text
        
            self.notes[indexPath.row].setValue(newNote, forKey: "content")
            
            self.dataBase.save(self.notes[indexPath.row]) { (updateRecord, error) in
                
                if error != nil {
                    
                    print(error?.localizedDescription)
                } else {
        
                    DispatchQueue.main.async {
                        
                        tableView.reloadData()
                    }
                }
            }
        }
        
        alert.addAction(editButton)
        self.present(alert, animated: true, completion: nil)
    }
}

