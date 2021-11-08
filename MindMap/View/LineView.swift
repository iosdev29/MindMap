//
//  LineView.swift
//  MindMap
//
//  Created by Alina on 08.11.2021.
//

import UIKit

class LineView: UIView {

    private var parentView: NodeView?
    private var childView: NodeView?
    
    // MARK: Init
    
    init(parentView: NodeView, childView: NodeView) {
        super.init(frame: CGRect.zero)

        self.parentView = parentView
        self.childView = childView
        self.backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func updateFrame() {
        self.frame = parentView!.frame.union(childView!.frame)
        self.setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
//        let path = UIBezierPath()
//        let origin = parentView!.center - self.frame.origin
//        let destination = childView!.center - self.frame.origin
//
//        let halfOfViewWidth = (destination.x - origin.x) / 2
//        let point1 = CGPoint(x: origin.x + halfOfViewWidth, y: origin.y)
//        let point2 = CGPoint(x: destination.x - halfOfViewWidth, y: destination.y)
//        path.move(to: origin)
//        path.addCurve(to: destination, controlPoint1: point1, controlPoint2: point2)
//
//        let shapeLayer = CAShapeLayer()
//        shapeLayer.path = path.cgPath
//        shapeLayer.fillColor = UIColor.clear.cgColor
//        shapeLayer.strokeColor = UIColor.blue.cgColor
//        shapeLayer.lineWidth = 1.5
//
//        self.layer.addSublayer(shapeLayer)
        
        let path = UIBezierPath()
        path.lineWidth = 2.0
        UIColor.black.setStroke()
        let origin = parentView!.center - self.frame.origin
        let destination = childView!.center - self.frame.origin
        let halfOfViewWidth = (destination.x - origin.x) * 0.5
        path.move(to: origin)
        let point1 = CGPoint(x: origin.x + halfOfViewWidth, y: origin.y)
        let point2 = CGPoint(x: destination.x - halfOfViewWidth, y: destination.y)
        path.addCurve(to: destination, controlPoint1: point1, controlPoint2: point2)
        path.stroke()
    }
}

// MARK: Extend operand - for CGPoint

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y);
}

