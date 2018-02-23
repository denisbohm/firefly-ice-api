//
//  ActivityView.swift
//  Firefly Activity
//
//  Created by Denis Bohm on 12/28/17.
//  Copyright © 2017 Firefly Design LLC. All rights reserved.
//

import UIKit

@IBDesignable
class ActivityView: PlotView {

    var spans: [Activity.Span] = []

    func setTimeAxisAll() {
        if spans.isEmpty {
            setTimeAxis(min: 0.0, max: 1.0)
            return
        }
        
        let min = spans.first!.timeRange().start
        let max = spans.last!.timeRange().end
        setTimeAxis(min: min, max: max)
    }
    
    func setVmaAxisAll() {
        let epsilon: Float = 0.0
        valueAxis.max = Double(spans.reduce(epsilon) { max($0, $1.vmas.reduce(epsilon) { max($0, $1) }) })
    }
    
    override func setTimeAxisEnded() {
    }
    
    func setSpans(spans: [Activity.Span]) {
        self.spans = spans
    }
    
    override func query(identifier: String, start: Date, end: Date) {
        let datastore = Datastore(identifier: identifier)
        self.spans = datastore.query(start: start.timeIntervalSince1970, end: end.timeIntervalSince1970)
    }

    func gaps() -> [(start: TimeInterval, end: TimeInterval)] {
        var gaps: [(start: TimeInterval, end: TimeInterval)] = []
        if spans.count > 1 {
            var end = spans.first!.timeRange().end
            for span in spans.suffix(from: 1) {
                let (start, nextEnd) = span.timeRange()
                gaps.append((start: end, end: start))
                end = nextEnd
            }
        }
        return gaps
    }
    
    func summarize(currentPath: UIBezierPath, previousCount: Int, previousX: Int, previousSum: Float, previousMin: Float, previousMax: Float) {
        let px = Double(plotInsets.left) + Double(previousX)
        let mean = Double(previousSum) / Double(previousCount)
        let h = Double(self.frame.size.height - plotInsets.bottom)
        let valueScale = valueAxis.scale(CGFloat(h))
        let y = h - (mean - valueAxis.min) * valueScale
        addPoint(path: currentPath, x: px, y: y)
        let y0 = h - (Double(previousMin) - valueAxis.min) * valueScale
        let y1 = h - (Double(previousMax) - valueAxis.min) * valueScale
        let height = y0 - y1
        UIBezierPath(rect: CGRect(x: px, y: y1, width: 1.0, height: height)).fill()
    }
    
    override func drawContent(_ dirtyRect: CGRect) {
        let timeScale = timeAxis.scale(bounds.size.width)
        for span in spans {
            let timeRange = span.timeRange()
            if (timeRange.end < timeAxis.min) || (timeRange.start > timeAxis.max) {
                continue
            }
            
            // for performance, calculate which vmas will just extend outside view and only draw between those...
            let first = Swift.max(Int(timeAxis.min - timeRange.start) / span.interval - 1, 0)
            let last = Swift.min(Int(timeAxis.max - timeRange.start) / span.interval + 1, span.vmas.count)
            var time = timeRange.start + Double(first * span.interval)
            let vmas = span.vmas[first ..< last]
            
            var previousCount = 0
            var previousX = 0
            var previousSum: Float = 0.0
            var previousMin: Float = 0.0
            var previousMax: Float = 0.0
            
            UIColor.lightGray.setFill()
            UIColor.black.setStroke()
            let currentPath = UIBezierPath()
            
            for vma in vmas {
                let x = Int(round((time - timeAxis.min) * timeScale))
                
                if (previousCount == 0) {
                    previousX = x
                    previousMin = vma
                    previousMax = vma
                } else {
                    if x != previousX {
                        summarize(currentPath: currentPath, previousCount: previousCount, previousX: previousX, previousSum: previousSum, previousMin: previousMin, previousMax: previousMax)
                        
                        previousCount = 0
                        previousX = x
                        previousSum = 0.0
                        previousMin = vma
                        previousMax = vma
                    }
                }
                
                previousCount += 1
                previousSum += vma
                if vma < previousMin {
                    previousMin = vma
                }
                if vma > previousMax {
                    previousMax = vma
                }
                
                time += TimeInterval(span.interval)
            }
            if previousCount > 0 {
                summarize(currentPath: currentPath, previousCount: previousCount, previousX: previousX, previousSum: previousSum, previousMin: previousMin, previousMax: previousMax)
            }
            currentPath.stroke()
        }
        
        UIColor.red.setFill()
        drawGaps(gaps: gaps())
    }
    
}
