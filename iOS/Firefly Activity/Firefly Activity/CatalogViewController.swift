//
//  CatalogViewController.swift
//  Firefly Activity
//
//  Created by Denis Bohm on 1/10/18.
//  Copyright © 2018 Firefly Design LLC. All rights reserved.
//

import UIKit
import FireflyDevice

class CatalogViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    class Item {
        
        let fireflyIce: FDFireflyIce
        var name: String
        var associated: Bool
        
        init(fireflyIce: FDFireflyIce, name: String, associated: Bool) {
            self.fireflyIce = fireflyIce
            self.name = name
            self.associated = associated
        }
        
    }
    
    @IBOutlet var tableView: UITableView!
    
    var selectedCallback: ((_ item: Item) -> Void)? = nil
    var editCallback: ((_ item: Item) -> Void)? = nil
    var deleteCallback: ((_ item: Item) -> Void)? = nil

    var items: [Item] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "DeviceCell")!
        cell.textLabel?.text = item.fireflyIce.name
        cell.textLabel?.textColor = item.associated ? UIColor.black : UIColor.gray
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let callback = selectedCallback {
            let item = items[indexPath.row]
            callback(item)
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let editAction = UITableViewRowAction(style: .default, title: "Rename", handler: { (action, indexPath) in
            if let callback = self.editCallback {
                let item = self.items[indexPath.row]
                callback(item)
            }
        })
        editAction.backgroundColor = UIColor.blue
        
        let deleteAction = UITableViewRowAction(style: .default, title: "Forget", handler: { (action, indexPath) in
            if let callback = self.deleteCallback {
                let item = self.items[indexPath.row]
                callback(item)
            }
        })
        deleteAction.backgroundColor = UIColor.red
        
        return [editAction, deleteAction]
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Forget"
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let callback = deleteCallback {
                let item = items[indexPath.row]
                callback(item)
            }
        }
    }

    func load(fireflyIces: [FDFireflyIce]) {
        items.removeAll()
        for fireflyIce in fireflyIces {
            items.append(Item(fireflyIce: fireflyIce, name: fireflyIce.name, associated: true))
        }
        tableView.reloadData()
    }

    func indexInTableView(fireflyIce: FDFireflyIce) -> Int? {
        return items.index { item in return item.fireflyIce == fireflyIce }
    }
    
    func delete(item: Item) {
        if let index = indexInTableView(fireflyIce: item.fireflyIce) {
            items.remove(at: index)
            let indexPath = IndexPath(row: index, section: 0)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    func display(fireflyIce: FDFireflyIce) {
        if let index = indexInTableView(fireflyIce: fireflyIce) {
            let item = items[index]
            if item.name != fireflyIce.name {
                item.name = fireflyIce.name
                let indexPath = IndexPath(row: index, section: 0)
                tableView.reloadRows(at: [indexPath], with: .fade)
            }
            return
        }
        
        let indexPath = IndexPath(row: items.count, section: 0)
        items.append(Item(fireflyIce: fireflyIce, name: fireflyIce.name, associated: false))
        tableView.insertRows(at: [indexPath], with: .fade)
    }
    
    func associate(fireflyIce: FDFireflyIce) {
        if let index = indexInTableView(fireflyIce: fireflyIce) {
            let item = items[index]
            if !item.associated || (item.name != fireflyIce.name) {
                item.associated = true
                item.name = fireflyIce.name
                let indexPath = IndexPath(row: index, section: 0)
                tableView.reloadRows(at: [indexPath], with: .fade)
            }
        }
    }
    
}
