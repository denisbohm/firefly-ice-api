//
//  ViewController.swift
//  Firefly Activity Access
//
//  Created by Denis Bohm on 1/20/18.
//  Copyright © 2018 Firefly Design LLC. All rights reserved.
//

import Cocoa
import CloudKit

class ViewController: NSViewController {

    @IBOutlet var syncButton: NSButton?
    @IBOutlet var syncProgressIndicator: NSProgressIndicator?
    @IBOutlet var logTextView: NSTextView?
    
    enum LocalError: Error {
        case contentModificationDateNotFound
        case directoryNotFound
        case assetNotFound
    }
    
    struct State {
        let queryOperation: CKQueryOperation
    }
    
    private let dispatchQueue = DispatchQueue(label:"ViewControllerQueue")
    private var cancelValue: Bool = false

    var state: State? = nil
    var records: [CKRecord] = []
    var queuedOperations: [CKDatabaseOperation] = []
    var currentOperation: CKDatabaseOperation? = nil

    var database: CKDatabase {
        get {
            let container = CKContainer(identifier: "iCloud.com.fireflydesign.Firefly-Activity")
            return container.publicCloudDatabase
        }
    }
    
    var cancel: Bool {
        set(value) {
            dispatchQueue.sync {
                cancelValue = value
            }
        }
        get {
            var value: Bool = false
            dispatchQueue.sync {
                value = cancelValue
            }
            return value
        }
    }
    
    func isOutOfDate(url: URL, date: Date) -> Bool {
        if !FileManager.default.fileExists(atPath: url.path) {
            return true
        }
        if let values = try? url.resourceValues(forKeys: [.contentModificationDateKey]) {
            if let contentModificationDate = values.contentModificationDate {
                return date > contentModificationDate
            }
        }
        return true
    }
    
    func ensure(directory: URL) {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    func nextOperation() {
        if queuedOperations.isEmpty {
            syncComplete()
            return
        }
        let operation = queuedOperations.removeFirst()
        currentOperation = operation
        database.add(operation)
    }
    
    func save(url: URL, path: String, modificationDate: Date, record: CKRecord) {
        if cancel {
            syncComplete()
            return
        }
        guard let asset = record["data"] as? CKAsset else {
            return
        }
        let fileManager = FileManager.default
        let calendar = Calendar.current
        ensure(directory: url.deletingLastPathComponent())
        do {
            let data = try Data(contentsOf: asset.fileURL)
            try data.write(to: url)
            // add a millisecond to handle case where date representations do not have the same resolution (also possibly due to very small number conversion issues) -denis
            let date = calendar.date(byAdding: .nanosecond, value: 1000000, to: modificationDate)!
            let attributes = [FileAttributeKey.modificationDate: date]
            try fileManager.setAttributes(attributes, ofItemAtPath: url.path)
            log("updated out of date file " + path)
        } catch {
            log("error updating out of date file " + path)
        }
        
        nextOperation()
    }

    func queueGet(url: URL, path: String, modificationDate: Date, recordID: CKRecordID) {
        let predicate = NSPredicate(format: "recordID == %@", recordID)
        let query = CKQuery(recordType: "File", predicate: predicate)
        let operation = CKQueryOperation(query: query)
        operation.desiredKeys = ["path", "fileModificationDate", "data"]
        operation.qualityOfService = .userInteractive
        var records: [CKRecord] = []
        operation.recordFetchedBlock = { (record) in
            records.append(record)
        }
        operation.queryCompletionBlock = { (cursor, error) in
            DispatchQueue.main.async {
                if let error = error {
                    self.log("error: \(error.localizedDescription)")
                    self.syncComplete()
                    return
                }
                for record in records {
                    self.save(url: url, path: path, modificationDate: modificationDate, record: record)
                }
            }
        }
        queuedOperations.append(operation)
    }

    func queryFilesComplete(error: Error?) {
        if let error = error {
            self.log("error: \(error.localizedDescription)")
            self.syncComplete()
            return
        }
        
        let directory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads/Firefly Activity/")
        log("destinatioin directory: \(directory.path)")
        ensure(directory: directory)
        for record in records {
            if cancel {
                syncComplete()
                return
            }
            guard let path = record["path"] as? String else {
                continue
            }
            guard let modificationDate = record["fileModificationDate"] as? Date else {
                continue
            }
            let url = directory.appendingPathComponent(path)
            if isOutOfDate(url: url, date: modificationDate) {
                queueGet(url: url, path: path, modificationDate: modificationDate, recordID: record.recordID)
            }
        }
        
        nextOperation()
    }
    
    func queryFiles(cursor: CKQueryCursor? = nil) {
        if cancel {
            syncComplete()
            return
        }
        
        let operation:CKQueryOperation
        if let cursor = cursor {
            operation = CKQueryOperation(cursor: cursor)
        } else {
            let predicate = NSPredicate(value: true)
            let query = CKQuery(recordType: "File", predicate: predicate)
            operation = CKQueryOperation(query: query)
        }
        operation.desiredKeys = ["path", "fileModificationDate"]
        operation.qualityOfService = .userInteractive
        operation.recordFetchedBlock = { (record) in
            DispatchQueue.main.async {
                self.records.append(record)
            }
        }
        operation.queryCompletionBlock = { (cursor, error) in
            DispatchQueue.main.async {
                if let cursor = cursor {
                    self.queryFiles(cursor: cursor)
                } else {
                    self.queryFilesComplete(error: error)
                }
            }
        }
        state = State(queryOperation: operation)
        database.add(operation)
    }
    
    @IBAction func sync(_ sender: AnyObject) {
        if state != nil {
            cancel = true
            return
        }
        
        syncButton?.title = "Cancel"
        syncProgressIndicator?.isHidden = false
        syncProgressIndicator?.startAnimation(self)
        logTextView?.textStorage?.mutableString.setString("")
        
        cancel = false
        queryFiles()
    }
    
    func syncComplete() {
        state = nil
        records.removeAll()
        queuedOperations.removeAll()
        currentOperation = nil
        
        syncButton?.title = "Sync"
        self.syncProgressIndicator?.stopAnimation(self)
        self.syncProgressIndicator?.isHidden = true
    }
    
    func log(_ string: String) {
        logTextView?.textStorage?.mutableString.append(string + "\n")
    }
    
    func debug(_ string: String) {
        log(string)
    }
    
    func selectDirectory() {
        let openPanel = NSOpenPanel()
        openPanel.prompt = "Select Directory"
        openPanel.worksWhenModal = true
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.canChooseFiles = false
        openPanel.resolvesAliases = true
        openPanel.beginSheetModal(for: view.window!, completionHandler: { result in
            if result == NSApplication.ModalResponse.OK {
                let url = openPanel.url!
                print(url.path)
                let bookmarkData = try! url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                var stale: Bool = false
                let bookmarkURL = try! URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &stale)
                print(bookmarkURL!.path)
                UserDefaults.standard.set(bookmarkURL, forKey: "directory")
                UserDefaults.standard.synchronize()
            } else {
                print("nothing chosen")
            }
        })
    }

}
