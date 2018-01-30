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
    var studyIdentifier: String? = nil
    
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
        
        studyIdentifier = userDefaults.string(forKey: "studyIdentifier")
    }
    
    func save(studyIdentifier: String) {
        self.studyIdentifier = studyIdentifier
        
        let userDefaults = UserDefaults.standard
        
        userDefaults.set(studyIdentifier, forKey: "studyIdentifier")
    }
    
}
