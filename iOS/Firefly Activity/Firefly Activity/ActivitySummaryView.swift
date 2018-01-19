//
//  ActivitySummaryView.swift
//  Firefly Activity
//
//  Created by Denis Bohm on 1/10/18.
//  Copyright © 2018 Firefly Design LLC. All rights reserved.
//

import UIKit

@IBDesignable
class ActivitySummaryView: PlotView {
    
    struct Style {
        let backgroundColor: UIColor
    }
    
    struct Summary {
        let start: Date
        let end: Date
        let activity: Float
        let intervals: Int
    }
    
    struct Day {
        let start: Date
        let end: Date
        let label: String
        let summaries: [Summary]
    }
    
    var identifier: String = "anonymous"
    let activeVmaLevel: Float = 0.5
    let minValueShown: Float = 35.0 / (10.0 * 60.0) // 30 minutes of activity spread evenly over 10 hours
    let goalValueShown: Float = 30.0 / (10.0 * 60.0) // 30 minutes of activity spread evenly over 10 hours

    var days: [Day] = []
    var gaps: [(start: TimeInterval, end: TimeInterval)] = []

    override func initialize() {
        super.initialize()
        valueAxis.label = "Activity"
    }
    
    func getGaps(datastore: Datastore, start: Date, end: Date) {
        gaps.removeAll()
        let spans = datastore.query(start: start.timeIntervalSince1970, end: end.timeIntervalSince1970)
        if spans.count > 1 {
            var end = spans.first!.timeRange().end
            for span in spans.suffix(from: 1) {
                let (start, nextEnd) = span.timeRange()
                gaps.append((start: end, end: start))
                end = nextEnd
            }
        }
    }

    func summarize(datastore: Datastore, start: Date, end: Date) -> Summary {
        var intervals = 0
        var activeIntervals = 0
        let spans = datastore.query(start: start.timeIntervalSince1970, end: end.timeIntervalSince1970)
        for span in spans {
            for vma in span.vmas {
                intervals += 1
                if vma > activeVmaLevel {
                    activeIntervals += 1
                }
            }
        }
//        let intervals = Int(end.timeIntervalSince1970 - start.timeIntervalSince1970) / datastore.interval
        let activity = (intervals == 0) ? 0.0 : Float(activeIntervals) / Float(intervals)
//        let activity = Float(arc4random_uniform(100)) / 100.0
        return Summary(start: start, end: end, activity: activity, intervals: intervals)
    }
    
    override func query(identifier: String, start: Date, end: Date) {
        let datastore = Datastore(identifier: identifier)
        
        getGaps(datastore: datastore, start: start, end: end)
        
        days.removeAll()
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        let startDate = calendar.date(from: calendar.components([.era, .year, .month, .day], from: start))!
        let endDate = calendar.date(byAdding: .day, value: 1, to: calendar.date(from: calendar.components([.era, .year, .month, .day], from: end))!, options: [])!
        var startOfDay = startDate
        while startOfDay < endDate {
            let sunrise = calendar.date(byAdding: .hour, value: 6, to: startOfDay)!
            let midday = calendar.date(byAdding: .hour, value: 12, to: startOfDay)!
            let sunset = calendar.date(byAdding: .hour, value: 18, to: startOfDay)!
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            let summaries = [
                summarize(datastore: datastore, start: startOfDay, end: sunrise),
                summarize(datastore: datastore, start: sunrise, end: midday),
                summarize(datastore: datastore, start: midday, end: sunset),
                summarize(datastore: datastore, start: sunset, end: endOfDay),
            ]
            let label = dayFormatter.string(from: startOfDay)
            days.append(Day(start: startOfDay, end: endOfDay, label: label, summaries: summaries))
            
            startOfDay = endOfDay
        }
    }
    
    override func setTimeAxisEnded() {
        let minTime = Date(timeIntervalSince1970: timeAxis.min)
        let maxTime = Date(timeIntervalSince1970: timeAxis.max)
        var maxActivity: Float = 0.0
        for day in days {
            for summary in day.summaries {
                if (summary.end < minTime) || (summary.start > maxTime) {
                    continue
                }
                if summary.activity > maxActivity {
                    maxActivity = summary.activity
                }
            }
        }
        valueAxis.max = Double(Swift.max(maxActivity, minValueShown))
        setNeedsDisplay()
    }

    override func drawContent(_ dirtyRect: CGRect) {
        let context = UIGraphicsGetCurrentContext()!
        context.saveGState()
        context.clip(to: CGRect(x: plotInsets.left, y: 0, width: frame.size.width - plotInsets.left - plotInsets.right, height: frame.size.height))
        context.translateBy(x: plotInsets.left, y: plotInsets.top)

        let styles = [
            Style(backgroundColor: UIColor(red: 0.90, green: 0.94, blue: 1.00, alpha: 1.0)),
            Style(backgroundColor: UIColor(red: 1.00, green: 0.90, blue: 0.51, alpha: 1.0)),
            Style(backgroundColor: UIColor(red: 1.00, green: 0.90, blue: 0.51, alpha: 1.0)),
            Style(backgroundColor: UIColor(red: 0.90, green: 0.94, blue: 1.00, alpha: 1.0)),
        ]
        let darkGreen = UIColor(red: 0.14, green: 0.64, blue: 0.00, alpha: 1.0)
        
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        let now = Date()
        let today = calendar.date(from: calendar.components([.era, .year, .month, .day], from: now))!
        
        let line = UIBezierPath()
        var areas: [(summary: Summary, x1: CGFloat, x2: CGFloat, y: CGFloat, style: Style)] = []
        let (font, attributes) = getfontAndAttributes()
        let w = Double(frame.size.width - plotInsets.left - plotInsets.right)
        let h = Double(frame.size.height - plotInsets.top - plotInsets.bottom)
        let valueScale = valueAxis.scale(CGFloat(h))
        let timeScale = timeAxis.scale(CGFloat(w))
        for day in days {
            var index = 0
            for summary in day.summaries {
                let style = styles[index]
                let x1 = (Double(summary.start.timeIntervalSince1970) - timeAxis.min) * timeScale
                let x2 = (Double(summary.end.timeIntervalSince1970) - timeAxis.min) * timeScale
                let x = (x2 + x1) / 2.0
                let y = h - (Double(summary.activity) - valueAxis.min) * valueScale
                let rect = UIBezierPath(rect: CGRect(x: x1, y: Double(plotInsets.top), width: x2 - x1, height: h))
                style.backgroundColor.setFill()
                rect.fill()
                if summary.intervals > 0 {
                    addPoint(path: line, x: x, y: y)
                }
                areas.append((summary: summary, x1: CGFloat(x1), x2: CGFloat(x2), y: CGFloat(y), style: style))
                index += 1
            }
            let x = (Double(day.end.timeIntervalSince1970 + day.start.timeIntervalSince1970) / 2.0 - timeAxis.min) * timeScale
            let y = Double(bounds.size.height - font.lineHeight)
            let label = day.start == today ? "today" : day.label
            let dx = Double((label as NSString).size(withAttributes: attributes).width) / 2.0
            label.draw(at: CGPoint(x: x - dx, y: y), withAttributes: attributes)
        }
        
        UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.5).setFill()
        drawGaps(gaps: gaps)

        line.lineWidth = 2.0
        line.lineJoinStyle = .round
        darkGreen.setStroke()
        line.stroke()
        
        context.clip(to: CGRect(x: 0, y: 0, width: frame.size.width - plotInsets.left - plotInsets.right, height: frame.size.height - plotInsets.top - plotInsets.bottom))
        UIColor.green.setFill()
        UIColor.black.setStroke()
        for area in areas {
            if area.summary.intervals > 0 {
                let x = (area.x2 + area.x1) / 2.0
                let shape = UIBezierPath(ovalIn: CGRect(x: x - 4, y: area.y - 4, width: 8, height: 8))
                shape.lineWidth = 2.0
                shape.fill()
                shape.stroke()
            }
        }
        
        let dashes: [CGFloat] = [2.0, 2.0]
        
        let y = h - (Double(goalValueShown) - valueAxis.min) * valueScale
        let goal = UIBezierPath()
        goal.move(to: CGPoint(x: 0.0, y: y))
        goal.addLine(to: CGPoint(x: w, y: y))
        goal.lineWidth = 2.0
        goal.setLineDash(dashes, count: dashes.count, phase: 0.0)
        darkGreen.setStroke()
        goal.stroke()
        
        let x = (Double(now.timeIntervalSince1970) - timeAxis.min) * timeScale
        let nowLine = UIBezierPath()
        nowLine.move(to: CGPoint(x: x, y: 0.0))
        nowLine.addLine(to: CGPoint(x: x, y: h))
        nowLine.lineWidth = 2.0
        nowLine.setLineDash(dashes, count: dashes.count, phase: 0.0)
        UIColor.black.setStroke()
        nowLine.stroke()
        
        context.restoreGState()
    }
    
}
