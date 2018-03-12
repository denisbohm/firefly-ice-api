//
//  Datastore.swift
//  Firefly Activity
//
//  Created by Denis Bohm on 1/1/18.
//  Copyright © 2018 Firefly Design LLC. All rights reserved.
//

import FireflyDevice
import Foundation

class Datastore: Store {

    let bytesPerRecord = 8
    let interval = 10

    var data: Data = Data()
    
    override func initialDayContents(timeRange: (start: Int, end: Int)) -> Data {
        let recordCount = (timeRange.end - timeRange.start) / interval
        return Data(count: bytesPerRecord * recordCount)
    }

    func load(day: String) throws {
        try ensure(day: day)
        if let url = url {
            self.data = try Data(contentsOf: url)
        }
    }
    
    func save() {
        guard let url = url else {
            return
        }

        try? self.data.write(to: url, options: [.atomic])

        self.data = Data()
        clear()
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
                try find(day: day, ensure: false)
                if let url = url {
                    self.data = try Data(contentsOf: url)
                }
            } catch {
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
