//
//  ActivityManager.swift
//  Firefly Activity
//
//  Created by Denis Bohm on 1/19/18.
//  Copyright © 2018 Firefly Design LLC. All rights reserved.
//

import UIKit

class ActivityManager {
    
    static let shared = ActivityManager()
    
    let installationDate: Date!
    let installationUUID: String!
    
    var cloud: Cloud? = nil
    
    init() {
        let userDefaults = UserDefaults.standard
        
        if let installationDate = userDefaults.object(forKey: "installationDate") as? Date {
            self.installationDate = installationDate
        } else {
            self.installationDate = Date()
            userDefaults.set(self.installationDate, forKey: "installatonDate")
        }
        
        if let installationUUID = userDefaults.string(forKey: "installationUUID") {
            self.installationUUID = installationUUID
        } else {
            self.installationUUID = UUID().uuidString
            userDefaults.set(self.installationUUID, forKey: "installationUUID")
        }
        
        let fileManager = FileManager.default
        guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            NSLog("document directory not found")
            return
        }
        let directory = documentDirectory.appendingPathComponent("database", isDirectory: true)
        if let contents = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]) {
            for child in contents {
                if !child.isDirectory {
                    try? fileManager.removeItem(atPath: child.path)
                }
            }
        }
    }
    
    func pushToCloud() {
        if cloud != nil {
            NSLog("deferring push to cloud - previous cloud push still running")
        }
        let fileManager = FileManager.default
        guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            NSLog("document directory not found")
            return
        }
        let directory = documentDirectory.appendingPathComponent("database", isDirectory: true)
        cloud = Cloud(installationUUID: installationUUID, directory: directory) { (error) in
            DispatchQueue.main.async {
                self.pushToCloudComplete(error: error)
            }
        }
        cloud!.start()
    }
    
    func pushToCloudComplete(error: Error?) {
        cloud = nil
    }

}
