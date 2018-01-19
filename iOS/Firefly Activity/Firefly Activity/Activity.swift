//
//  Activity.swift
//  Firefly Activity
//
//  Created by Denis Bohm on 1/2/18.
//  Copyright © 2018 Firefly Design LLC. All rights reserved.
//

import Foundation

class Activity {
    
    struct Item {
        let day: String
        let time: UInt32
        let vmas: [Float]
    }
    
    class Span {
        
        let date: Date
        let interval: Int
        let vmas: [Float]
        
        init(date: Date, interval: Int, vmas: [Float]) {
            self.date = date
            self.interval = interval
            self.vmas = vmas
        }
        
        func timeRange() -> (start: TimeInterval, end: TimeInterval) {
            let start = date.timeIntervalSince1970
            let end = start + Double(vmas.count * interval)
            return (start: start, end: end)
        }
        
    }
    
    static func dayConversions() -> (dateFormatter: DateFormatter, calendar: NSCalendar) {
        let timeZone = TimeZone(identifier: "UTC")!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = timeZone
        
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        calendar.timeZone = timeZone
        
        return (dateFormatter: dateFormatter, calendar: calendar)
    }
    
    static func splitByDay(time: UInt32, vmas: [Float]) -> [Item] {
        let (dateFormatter, calendar) = dayConversions()
        
        var results: [Item] = []
        var lastStartOfDay = calendar.startOfDay(for: Date(timeIntervalSince1970: TimeInterval(time)))
        var lastTime: UInt32 = time
        var lastIndex = 0
        for i in 1 ..< vmas.count {
            let thisTime = time + UInt32(i * 10)
            let startOfDay = calendar.startOfDay(for: Date(timeIntervalSince1970: TimeInterval(thisTime)))
            if startOfDay != lastStartOfDay {
                let lastDay = dateFormatter.string(from: lastStartOfDay)
                let lastVmas: [Float] = Array(vmas[lastIndex ..< i])
                results.append(Item(day: lastDay, time: lastTime, vmas: lastVmas))
                
                lastStartOfDay = startOfDay
                lastTime = thisTime
                lastIndex = i
            }
        }
        let lastDay = dateFormatter.string(from: lastStartOfDay)
        let lastVmas: [Float] = Array(vmas[lastIndex ..< vmas.count])
        results.append(Item(day: lastDay, time: lastTime, vmas: lastVmas))
        return results
    }
    
    static func timeRange(day: String) -> (start: Int, end: Int) {
        let (dateFormatter, calendar) = dayConversions()

        let startDate = dateFormatter.date(from: day)!
        let start = Int(startDate.timeIntervalSince1970)
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        let end = Int(endDate.timeIntervalSince1970)
        return (start: start, end: end)
    }
    
    static func daysInRange(start: Date, end: Date) -> [String] {
        var days: [String] = []
        let (dateFormatter, calendar) = dayConversions()
        var startOfDay = calendar.startOfDay(for: start)
        while startOfDay < end {
            days.append(dateFormatter.string(from: startOfDay))
            startOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        }
        return days
    }
    
}
