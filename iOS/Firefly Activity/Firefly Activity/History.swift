//
//  History.swift
//  Firefly Activity
//
//  Created by Denis Bohm on 1/28/18.
//  Copyright © 2018 Firefly Design LLC. All rights reserved.
//

import Foundation

class History: Store {
    
    init() {
        super.init(identifier: "history")
    }
    
    func save(type: String, value: [String: Any]) throws {
        let day = Activity.day(of: Date())
        try ensure(day: day)
        guard let url = url else {
            return
        }
        
        let object: [String: Any] = [
            "type": type,
            "date": Activity.rfc3339(date: Date()),
            "value": value
        ]
        guard var data = try? JSONSerialization.data(withJSONObject: object, options: []) else {
            return
        }
        data.append(Data("\n".utf8))

        let fileHandle = try FileHandle(forWritingTo: url)
        fileHandle.seekToEndOfFile()
        fileHandle.write(data)
        fileHandle.closeFile()
    }
    
}
