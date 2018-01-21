//
//  Cloud.swift
//  Firefly Activity
//
//  Created by Denis Bohm on 1/18/18.
//  Copyright © 2018 Firefly Design LLC. All rights reserved.
//

import CloudKit
import Foundation

// sync a tree of files to the iCloud shared database
//
// NOTE! This code assumes that the files can be read at any time - i.e. use atomic file saves only with writing to these files
//
// NOTE! Most of the processing occurs on iCloud database threads.  This includes the "complete" closure call.
//
//    let fileManager = FileManager.default
//    if let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
//        let directory = documentDirectory.appendingPathComponent("database", isDirectory: true)
//        push(installationUUID: installationUUID, directory: directory)
//    }

class Cloud {
    
    class File {
        
        let path: String
        let modificationDate: Date
        
        init(path: String, modificationDate: Date) {
            self.path = path
            self.modificationDate = modificationDate
        }
        
    }
    
    class FileResult: File {
        
        let recordID: CKRecordID
        
        init(path: String, modificationDate: Date, recordID: CKRecordID) {
            self.recordID = recordID
            super.init(path: path, modificationDate: modificationDate)
        }
        
    }
    
    let fileRecordType = "File"
    let compress: Bool = false
    
    var database: CKDatabase {
        get {
            let container = CKContainer.default()
            return container.publicCloudDatabase
        }
    }

    let installationUUID: String
    let directory: URL
    let completion: (Error?) -> Void
    
    private var queryResults: [FileResult] = []
    private var currentOperation: CKDatabaseOperation? = nil
    private var queuedOperations: [CKDatabaseOperation] = []

    init(installationUUID: String, directory: URL, completion: @escaping (Error?) -> Void) {
        self.installationUUID = installationUUID
        self.directory = directory
        self.completion = completion
    }
    
    func start() {
        queryFiles()
    }
    
    private func nextOperation(error: Error?) {
        if let error = error {
            NSLog("Cloud modify records error: \(error.localizedDescription)")
            completion(error)
            return
        }
        NSLog("Cloud modify records success")
        if queuedOperations.isEmpty {
            completion(nil)
            return
        }
        let operation = queuedOperations.removeFirst()
        currentOperation = operation
        database.add(operation)
    }

    private func modifyRecordsCompletion(records: [CKRecord]?, recordIDs: [CKRecordID]?, error: Error?) {
        nextOperation(error: error)
    }
    
    private func queueSave(file: File, recordID: CKRecordID? = nil) {
        let record: CKRecord
        if let recordID = recordID {
            record = CKRecord(recordType: fileRecordType, recordID: recordID)
        } else {
            record = CKRecord(recordType: fileRecordType)
        }
        record["installationUUID"] = installationUUID as NSString
        record["path"] = file.path as NSString
        record["fileModificationDate" ] = file.modificationDate as NSDate
        let url = directory.appendingPathComponent(file.path)
        if compress {
            do {
                let data = try Data(contentsOf: url)
                let compressedData = try GZip.compress(data: data)
                let compressedFileURL = URL(fileURLWithPath: NSTemporaryDirectory() + "/" + NSUUID().uuidString)
                try compressedData.write(to: compressedFileURL)
                record["data"] = CKAsset(fileURL: compressedFileURL)
            } catch {
                NSLog("Cloud compress error: \(error.localizedDescription)")
                record["data"] = CKAsset(fileURL: url)
            }
        } else {
            record["data"] = CKAsset(fileURL: url)
        }
        let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        operation.qualityOfService = .userInteractive
        operation.savePolicy = .allKeys
        operation.modifyRecordsCompletionBlock = modifyRecordsCompletion
        queuedOperations.append(operation)
    }
    
    private func queryRecordFetched(record: CKRecord) {
        if let path = record["path"] as? String, let modificationDate = record["fileModificationDate"] as? Date {
            queryResults.append(FileResult(path: path, modificationDate: modificationDate, recordID: record.recordID))
        }
    }
    
    private func queryCompletion(_ cursor: CKQueryCursor?, _ error: Error?) {
        NSLog("Cloud query completion")
        if let cursor = cursor {
            queryFiles(cursor: cursor)
        } else {
            queryFilesComplete(error: error)
        }
    }
    
    private func queryFiles(cursor: CKQueryCursor? = nil) {
        let operation: CKQueryOperation
        if let cursor = cursor {
            operation = CKQueryOperation(cursor: cursor)
        } else {
            let predicate = NSPredicate(format: "installationUUID == %@", installationUUID)
            let query = CKQuery(recordType: fileRecordType, predicate: predicate)
            operation = CKQueryOperation(query: query)
        }
        operation.qualityOfService = .userInteractive
        operation.desiredKeys = ["path", "fileModificationDate"]
        operation.recordFetchedBlock = queryRecordFetched
        operation.queryCompletionBlock = queryCompletion
        currentOperation = operation
        database.add(operation)
    }
    
    private func list(directory: URL) -> [File] {
        var files: [File] = []
        let fileManager = FileManager.default
        if let subpaths = fileManager.subpaths(atPath: directory.path) {
            for subpath in subpaths {
                if subpath.starts(with: "anonymous") {
                    continue
                }
                let url = directory.appendingPathComponent(subpath)
                if !url.isDirectory {
                    let path = url.path
                    if let attributes = try? fileManager.attributesOfItem(atPath: path) as NSDictionary {
                        if let modificationDate = attributes.fileModificationDate() {
                            files.append(File(path: subpath, modificationDate: modificationDate))
                        }
                    }
                }
            }
        }
        return files
    }
    
    private func queryFilesComplete(error: Error?) {
        if let error = error {
            NSLog("Cloud query error: \(error.localizedDescription)")
            completion(error)
            return
        }
        NSLog("Cloud query success")

        let localFiles = list(directory: directory)
        let localFileByPath = localFiles.reduce(into: [:]) { dictionary, file in dictionary[file.path] = file }
        let localPaths = Set(localFiles.map { $0.path })
    
        let queryResultByPath = queryResults.reduce(into: [:]) { dictionary, file in dictionary[file.path] = file }
        let queryPaths = Set(queryResults.map { $0.path })
        
        let newPaths = localPaths.subtracting(queryPaths)
        for path in newPaths {
            let file = localFileByPath[path]!
            queueSave(file: file)
        }
        let existingPaths = localPaths.intersection(queryPaths)
        for path in existingPaths {
            let localFile = localFileByPath[path]!
            let queryResult = queryResultByPath[path]!
            if localFile.modificationDate > queryResult.modificationDate {
                queueSave(file: localFile, recordID: queryResult.recordID)
            }
        }
        NSLog("Cloud \(queuedOperations.count) updates queued")

        nextOperation(error: nil)
    }
    
}
