//
//  PlotView.swift
//  Firefly Activity
//
//  Created by Denis Bohm on 1/10/18.
//  Copyright © 2018 Firefly Design LLC. All rights reserved.
//

import UIKit

protocol PlotViewDelegate {
    
    func plotView(timeAxisChange range: (start: Double, end: Double))
    
}

@IBDesignable
class PlotView: UIView, UIGestureRecognizerDelegate {
    
    class Axis {
        
        var min = 0.0
        var max = 1.0
        
        var interval: Double {
            get {
                return max - min
            }
        }
        
        func scale(_ amount: CGFloat) -> Double {
            if interval == 0.0 {
                return 1.0
            }
            return Double(amount) / interval
        }
        
    }
    
    var plotViewDelegate: PlotViewDelegate? = nil
    var timeAxis = Axis()
    var valueAxis = Axis()
    var plotInsets = UIEdgeInsets(top: 0, left: 20, bottom: 20, right: 0)
    var dateFormatter = DateFormatter()
    var pinch = (t0: 0.0, t1: 0.0)
    
    override init(frame frameRect: CGRect) {
        super.init(frame:frameRect);
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    func initialize() {
        dateFormatter.dateFormat =  "hh:mm:ss"
        
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action:#selector(handlePinch(recognizer:)))
        pinchGestureRecognizer.delegate = self
        addGestureRecognizer(pinchGestureRecognizer)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action:#selector(handlePan(recognizer:)))
        panGestureRecognizer.delegate = self
        addGestureRecognizer(panGestureRecognizer)
    }
    
    func query(identifier: String, start: Date, end: Date) {
        preconditionFailure("this method must be overridden")
    }
    
    func setTimeAxisEnded() {
        preconditionFailure("this method must be overridden")
    }
    
    @objc func handlePinch(recognizer: UIPinchGestureRecognizer) {
        if recognizer.numberOfTouches >= 2 {
            let width = self.frame.width - plotInsets.left - plotInsets.right
            let oldTimeScale = timeAxis.scale(width)
            let xa = Double(recognizer.location(ofTouch: 0, in: self).x - plotInsets.left)
            let xb = Double(recognizer.location(ofTouch: 1, in: self).x - plotInsets.left)
            let x0 = Swift.min(xa, xb)
            let x1 = Swift.max(xa, xb)
            if recognizer.state == .began {
                pinch.t0 = timeAxis.min + x0 / oldTimeScale
                pinch.t1 = timeAxis.min + x1 / oldTimeScale
            }
            let newTimeScale = (x1 - x0) / (pinch.t1 - pinch.t0)
            let min = pinch.t0 - x0 / newTimeScale
            let max = min + Double(width) / newTimeScale
            setTimeAxis(min: min, max: max)
        }
        
        if recognizer.state == .ended {
            setTimeAxisEnded()
        }
    }
    
    @objc func handlePan(recognizer: UIPanGestureRecognizer) {
        let translation = Double(recognizer.translation(in: self).x)
        recognizer.setTranslation(CGPoint(x: 0.0, y: 0.0), in: self)
        
        let width = self.frame.width - plotInsets.left - plotInsets.right
        let amount = -translation / timeAxis.scale(width)
        setTimeAxis(min: timeAxis.min + amount, max: timeAxis.max + amount)
        
        if recognizer.state == .ended {
            setTimeAxisEnded()
        }
    }
    
    func setTimeAxis(min: Double, max: Double) {
        timeAxis.min = min
        timeAxis.max = max
        
        plotViewDelegate?.plotView(timeAxisChange: (start: min, end: max))
        
        setNeedsDisplay()
    }
    
    func toDateString(date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    func timeIntervalString(interval: TimeInterval) -> String {
        let milliseconds = Int(abs(interval) * 1000)
        let SSS = milliseconds % 1000
        let seconds = milliseconds / 1000
        let ss = seconds % 60
        let minutes = seconds / 60
        let mm = minutes % 60
        return "\(mm):\(ss).\(SSS)"
    }
    
    func drawRotatedText(text: String, at p: CGPoint, angle: CGFloat, font: UIFont, color: UIColor) {
        let attrs = [NSAttributedStringKey.font: font, NSAttributedStringKey.foregroundColor: color]
        let context = UIGraphicsGetCurrentContext()!
        context.saveGState()
        context.translateBy(x: p.x, y: p.y)
        context.rotate(by: angle * .pi / 180)
        text.draw(at: CGPoint(x: 0, y: 0), withAttributes: attrs)
        context.restoreGState()
    }
    
    func addPoint(path: UIBezierPath, x: Double, y: Double) {
        if path.isEmpty {
            path.move(to: CGPoint(x: x, y: y))
        } else {
            path.addLine(to: CGPoint(x: x, y: y))
        }
    }
    
    func drawBackground(_ dirtyRect: CGRect) {
        if let color = backgroundColor {
            color.setFill()
            UIBezierPath(rect: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)).fill()
        }
    }
    
    func drawGaps(gaps: [(start: TimeInterval, end: TimeInterval)]) {
        let x = Double(plotInsets.left)
        let y = Double(plotInsets.top)
        let plotWidth = bounds.size.width - plotInsets.left - plotInsets.right
        let plotHeight = Double(self.frame.size.height - plotInsets.bottom - plotInsets.top)
        let timeScale = timeAxis.scale(plotWidth)
        for (start, end) in gaps {
            let x1 = x + (start - timeAxis.min) * timeScale
            let x2 = x + (end - timeAxis.min) * timeScale
            let width = Swift.max(x2 - x1, 1.0)
            UIBezierPath(rect: CGRect(x: x1, y: y, width: width, height: plotHeight)).fill()
        }
    }
    
    func getfontAndAttributes() -> (font: UIFont, attributes: [NSAttributedStringKey: NSObject]) {
        let font = UIFont.systemFont(ofSize: 10)
        let attributes = [NSAttributedStringKey.font: font, NSAttributedStringKey.foregroundColor: UIColor.black]
        return (font: font, attributes: attributes)
    }
    
    func drawAxis(_ dirtyRect: CGRect) {
        let (font, attributes) = getfontAndAttributes()
        
        UIColor.magenta.setFill()
        let y = self.frame.size.height - plotInsets.bottom - 1.0
        let width = self.frame.size.width - plotInsets.left - plotInsets.right
        UIBezierPath(rect: CGRect(x: plotInsets.left, y: y, width: width, height: 1.0)).fill()
        let timeAxisName = "time"
        let tx = plotInsets.left
        let ty = bounds.size.height - font.ascender
        timeAxisName.draw(at: CGPoint(x: tx, y: ty), withAttributes: attributes)
        
        UIColor.magenta.setFill()
        let height = self.frame.size.height - plotInsets.bottom - plotInsets.top
        UIBezierPath(rect: CGRect(x: plotInsets.left, y: plotInsets.top, width: 1.0, height: height)).fill()
        let ry = self.frame.size.height - plotInsets.bottom
        drawRotatedText(text: "activity", at: CGPoint(x: 0.0, y: ry), angle: -90.0, font: font, color: UIColor.black)
    }

    func drawContent(_ dirtyRect: CGRect) {
        preconditionFailure("this method must be overridden")
    }
    
    override func draw(_ dirtyRect: CGRect) {
        super.draw(dirtyRect)
        drawBackground(dirtyRect)
        drawContent(dirtyRect)
        drawAxis(dirtyRect)
    }
    
}
