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
    
    class Section {
        
        let header: String
        var items: [Item] = []
        
        init(header: String) {
            self.header = header
        }
    }
    
    let associatedSectionIndex = 0
    let unassociatedSectionIndex = 1
    
    @IBOutlet var tableView: UITableView!
    
    var selectedCallback: ((_ item: Item) -> Void)? = nil
    var editCallback: ((_ item: Item) -> Void)? = nil
    var deleteCallback: ((_ item: Item) -> Void)? = nil

    var sections: [Section] = [Section(header: "Your Devices"), Section(header: "Other Nearby Devices")]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection sectionIndex: Int) -> String? {
        return sections[sectionIndex].header
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection sectionIndex: Int) -> Int {
        return sections[sectionIndex].items.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        let item = section.items[indexPath.row]
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "DeviceCell")!
        cell.textLabel?.text = item.fireflyIce.name
        cell.textLabel?.textColor = item.associated ? UIColor.black : UIColor.gray
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let callback = selectedCallback {
            let section = sections[indexPath.section]
            let item = section.items[indexPath.row]
            callback(item)
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let editAction = UITableViewRowAction(style: .default, title: "Rename", handler: { (action, indexPath) in
            if let callback = self.editCallback {
                let section = self.sections[indexPath.section]
                let item = section.items[indexPath.row]
                callback(item)
            }
        })
        editAction.backgroundColor = UIColor.blue
        
        let deleteAction = UITableViewRowAction(style: .default, title: "Forget", handler: { (action, indexPath) in
            if let callback = self.deleteCallback {
                let section = self.sections[indexPath.section]
                let item = section.items[indexPath.row]
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
                let section = sections[indexPath.section]
                let item = section.items[indexPath.row]
                callback(item)
            }
        }
    }

    func load(fireflyIces: [FDFireflyIce]) {
        for section in sections {
            section.items.removeAll()
        }
        let section = sections[associatedSectionIndex]
        for fireflyIce in fireflyIces {
            section.items.append(Item(fireflyIce: fireflyIce, name: fireflyIce.name, associated: true))
        }
        tableView.reloadData()
    }

    func indexPathInTableView(fireflyIce: FDFireflyIce) -> IndexPath? {
        for sectionIndex in 0 ..< sections.count {
            let section = sections[sectionIndex]
            if let rowIndex = section.items.index(where: { item in return item.fireflyIce == fireflyIce }) {
                return IndexPath(row: rowIndex, section: sectionIndex)
            }
        }
        return nil
    }
    
    func delete(item: Item) {
        if let indexPath = indexPathInTableView(fireflyIce: item.fireflyIce) {
            let section = sections[indexPath.section]
            section.items.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    func display(fireflyIce: FDFireflyIce) {
        if let indexPath = indexPathInTableView(fireflyIce: fireflyIce) {
            let section = sections[indexPath.section]
            let item = section.items[indexPath.row]
            if item.name != fireflyIce.name {
                item.name = fireflyIce.name
                tableView.reloadRows(at: [indexPath], with: .fade)
            }
            return
        }
        
        let section = sections[unassociatedSectionIndex]
        let indexPath = IndexPath(row: section.items.count, section: unassociatedSectionIndex)
        section.items.append(Item(fireflyIce: fireflyIce, name: fireflyIce.name, associated: false))
        tableView.insertRows(at: [indexPath], with: .fade)
    }
    
    func associate(fireflyIce: FDFireflyIce) {
        if let indexPath = indexPathInTableView(fireflyIce: fireflyIce) {
            let section = sections[indexPath.section]
            let item = section.items[indexPath.row]
            if indexPath.section == associatedSectionIndex {
                if item.name != fireflyIce.name {
                    item.name = fireflyIce.name
                    tableView.reloadRows(at: [indexPath], with: .fade)
                }
            } else {
                section.items.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                
                item.associated = true
                item.name = fireflyIce.name
                let newSection = sections[associatedSectionIndex]
                let newIndexPath = IndexPath(row: newSection.items.count, section: associatedSectionIndex)
                newSection.items.append(item)
                tableView.insertRows(at: [newIndexPath], with: .fade)
            }
        }
    }
    
}
