//
//  DatastoreInsert.swift
//  Firefly Activity
//
//  Created by Denis Bohm on 1/2/18.
//  Copyright © 2018 Firefly Design LLC. All rights reserved.
//

import FireflyDevice

class DatastoreInsert : NSObject, FDPullTaskUpload {
    
    let identifier: String
    var delegate: FDPullTaskUploadDelegate?
    var isConnectionOpen: Bool = false
    var site: String? = ""
    
    init(identifier: String, delegate: FDPullTaskUploadDelegate) {
        self.identifier = identifier
        self.delegate = delegate
    }
    
    func update(item: Activity.Item) throws {
        let datastore = Datastore(identifier: identifier)
        try datastore.load(day: item.day)
        
        var time = Int(item.time)
        for vma in item.vmas {
            try datastore.update(time: time, vma: vma)
            time += datastore.interval
        }
        
        datastore.save()
    }
    
    func post(_ site: String?, items: [Any], backlog: UInt) {
        do {
            for item in items {
                if let vmaItem = item as? FDVMAItem {
                    let time = UInt32(vmaItem.time)
                    let vmas = vmaItem.vmas.map { $0.floatValue }
                    let itemsByDay = Activity.splitByDay(time: time, vmas: vmas)
                    for itemByDay in itemsByDay {
                        try update(item: itemByDay)
                    }
                }
            }
        } catch {
            NSLog("error updating datastore: \(error)")
            return
        }
        
        delegate?.upload(self, complete: nil)
    }
    
    func cancel(_ error: Error?) {
        if let error = error {
            Log.error(error)
        }
    }
    
}

