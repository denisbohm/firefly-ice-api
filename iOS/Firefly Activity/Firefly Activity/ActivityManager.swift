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
    
}
