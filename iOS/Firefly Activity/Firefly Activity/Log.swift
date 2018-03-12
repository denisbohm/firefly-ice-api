//
//  Log.swift
//  Firefly Activity
//
//  Created by Denis Bohm on 3/12/18.
//  Copyright © 2018 Firefly Design LLC. All rights reserved.
//

import UIKit

public class Log {
    
    static let shared = Log()
    
    enum LocalError: Error {
        case CanNotFindDirectory
        case CanNotFindFile
        case CanNotCreateFile
        case CanNotOpenFile
    }
    
    let fileSizeLimit = 100000
    let fileSizeRoll = 50000
    let dateFormatter = ISO8601DateFormatter()
    var url: URL? = nil

    func getURL() throws -> URL {
        if url == nil {
            let fileManager = FileManager.default
            let roots = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
            guard let root = roots.first else {
                throw LocalError.CanNotFindDirectory
            }
            let directory = root.appendingPathComponent("log", isDirectory: true)
            if !fileManager.fileExists(atPath: directory.path) {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            }
            let url = directory.appendingPathComponent("debug").appendingPathExtension("txt")
            if !fileManager.fileExists(atPath: url.path) {
                if !fileManager.createFile(atPath: url.path, contents: nil, attributes: nil) {
                    throw LocalError.CanNotCreateFile
                }
            }
            self.url = url
        }
        return url!
    }
    
    func roll() {
        guard let url = try? getURL() else {
            return
        }
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        guard let fileSize = attributes?[FileAttributeKey.size] as? UInt64 else {
            return
        }
        if fileSize <= fileSizeLimit {
            return
        }
        guard let data = try? Data(contentsOf: url, options: []) else {
            return
        }
        let subdata = data.subdata(in: Int(fileSize) - fileSizeRoll ..< Int(fileSize))
        try? subdata.write(to: url, options: .atomic)
    }
    
    func append(message: String) {
        guard let url = try? getURL() else {
            return
        }
        guard let data = (message + "\n").data(using: .utf8) else {
            return
        }
        guard let fileHandle = FileHandle(forWritingAtPath: url.path) else {
            try? data.write(to: url, options: .atomic)
            return
        }
        defer {
            fileHandle.closeFile()
        }
        fileHandle.seekToEndOfFile()
        fileHandle.write(data)
        roll()
    }
    
    func getName(_ path: String) -> String {
        let components = path.components(separatedBy: "/")
        return components.isEmpty ? "" : components.last!
    }
    
    func log(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        let date = dateFormatter.string(from: Date())
        let name = getName(file)
        append(message: "\(date) \(name):\(line) \(function) \(message)")
    }
    
    static func info(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        Log.shared.log("info: " + message, file: file, line: line, function: function)
    }
    
    static func error(_ error: Error, file: String = #file, line: Int = #line, function: String = #function) {
        Log.shared.log("error: " + error.localizedDescription, file: file, line: line, function: function)
    }
    
}
