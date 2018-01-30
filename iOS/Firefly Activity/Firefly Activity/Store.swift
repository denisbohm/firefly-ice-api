//
//  Store.swift
//  Firefly Activity
//
//  Created by Denis Bohm on 1/29/18.
//  Copyright © 2018 Firefly Design LLC. All rights reserved.
//

import Foundation

class Store {
    
    enum LocalError: Error {
        case CanNotFindDirectory
        case CanNotCreateFile
        case CanNotOpenFile
        case InvalidState
        case InvalidDayTime
        case InvalidValue
    }
    
    let identifier: String
    var url: URL? = nil
    
    var timeRange = (start: 0, end: 0)

    init(identifier: String) {
        self.identifier = identifier
    }
    
    func ensure(day: String, count: Int = 0) throws {
        let timeRange = Activity.timeRange(day: day)
        let fileManager = FileManager.default
        let roots = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        guard let root = roots.first else {
            throw LocalError.CanNotFindDirectory
        }
        let directory = root.appendingPathComponent("database", isDirectory: true).appendingPathComponent(identifier, isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        }
        let url = directory.appendingPathComponent(day).appendingPathExtension("dat")
        if !fileManager.fileExists(atPath: url.path) {
            if !fileManager.createFile(atPath: url.path, contents: Data(count: count), attributes: nil) {
                throw LocalError.CanNotCreateFile
            }
        }
        self.url = url
        self.timeRange = timeRange
    }
    
    func clear() {
        self.url = nil
        self.timeRange = (start: 0, end: 0)
    }
    
}
