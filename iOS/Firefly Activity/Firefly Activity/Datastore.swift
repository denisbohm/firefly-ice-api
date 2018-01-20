//
//  Datastore.swift
//  Firefly Activity
//
//  Created by Denis Bohm on 1/1/18.
//  Copyright © 2018 Firefly Design LLC. All rights reserved.
//

import FireflyDevice
import Foundation

class Datastore {

    enum LocalError: Error {
        case CanNotFindDirectory
        case CanNotCreateFile
        case CanNotOpenFile
        case InvalidState
        case InvalidDayTime
    }
    
    let identifier: String
    let bytesPerRecord = 8
    let interval = 10

    var url: URL? = nil
    var data: Data = Data()
    var timeRange = (start: 0, end: 0)
    
    init(identifier: String) {
        self.identifier = identifier
    }

    func load(day: String) throws {
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
            let count = bytesPerRecord * (timeRange.end - timeRange.start) / interval
            if !fileManager.createFile(atPath: url.path, contents: Data(count: count), attributes: nil) {
                throw LocalError.CanNotCreateFile
            }
        }
        self.url = url
        self.data = try Data(contentsOf: url)  // fileHandle.readDataToEndOfFile()
        self.timeRange = timeRange
    }
    
    func save() {
        guard let url = url else {
            return
        }

        try? self.data.write(to: url, options: [.atomic])

        self.url = nil
        self.data = Data()
        self.timeRange = (start: 0, end: 0)
    }
    
    func update(time: Int, vma: Float) throws {
        if url == nil {
            NSLog("invalid state")
            throw LocalError.InvalidState
        }
        if (time < timeRange.start) || (time >= timeRange.end) {
            throw LocalError.InvalidDayTime
        }

        let binary = FDBinary()
        let flags = UInt32(1)
        binary.put(flags)
        binary.putFloat32(vma)
        let record = binary.dataValue()
        
        let offset = (time - timeRange.start) / interval
        let index = offset * bytesPerRecord
        data.replaceSubrange(index ..< (index + bytesPerRecord), with: record)
    }
    
    func query(start: TimeInterval, end: TimeInterval) -> [Activity.Span] {
        var spans: [Activity.Span] = []
        var vmas: [Float] = []
        var lastTime = 0
        let startTime = Int(start)
        let endTime = Int(end)
        let startDate = Date(timeIntervalSince1970: start)
        let endDate = Date(timeIntervalSince1970: end)
        let days = Activity.daysInRange(start: startDate, end: endDate)
        for day in days {
            do {
                try load(day: day)
            } catch {
                NSLog("warning: cannot load day \(day)")
                continue
            }
            var time = timeRange.start
            let binary = FDBinary(data: data)
            while binary.getRemainingLength() > bytesPerRecord {
                let flags = binary.getUInt32()
                let vma = binary.getFloat32()
                if (startTime < time) && (time < endTime) {
                    let valid = flags != 0
                    if valid {
                        if vmas.isEmpty {
                            lastTime = time
                        }
                        vmas.append(vma)
                    } else {
                        if !vmas.isEmpty {
                            spans.append(Activity.Span(date: Date(timeIntervalSince1970: TimeInterval(lastTime)), interval: interval, vmas: vmas))
                            lastTime = 0
                            vmas.removeAll()
                        }
                    }
                }
                time += interval
            }
        }
        if !vmas.isEmpty {
            spans.append(Activity.Span(date: Date(timeIntervalSince1970: TimeInterval(lastTime)), interval: interval, vmas: vmas))
        }
        return spans
    }
    
}
