import UIKit

class SplineView: UIView {
    
    // MARK: Stored properties
    var parentView: NodeView?
    var childView: NodeView?

    var color: UIColor = .white
    
    // MARK: Initialize
    init(parentView: NodeView, childView: NodeView, color: UIColor) {
        super.init(frame: CGRect.zero)
        
        self.parentView = parentView
        self.childView = childView
        self.color = color
        
        backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: Functions
    func update() {
        if let parentView = parentView, let childView = childView {
            self.frame = parentView.frame.union(childView.frame)
            self.setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath()
        path.lineWidth = 1.5
        
        self.color.setStroke()
        
        if let parentView = parentView, let childView = childView {
            let parentCenter = CGPoint(x: parentView.center.x - frame.origin.x, y: parentView.center.y - frame.origin.y)
            let childCenter = CGPoint(x: childView.center.x - frame.origin.x, y: childView.center.y - frame.origin.y)
                        
            path.move(to: parentCenter)
            
            let point1 = CGPoint(x: parentCenter.x + (childCenter.x - parentCenter.x) / 2, y: parentCenter.y)
            let point2 = CGPoint(x: childCenter.x - (childCenter.x - parentCenter.x) / 2, y: childCenter.y)
            
            path.addCurve(to: childCenter, controlPoint1: point1, controlPoint2: point2)
            path.stroke()
        }
    }
}
