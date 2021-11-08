//
//  MapViewController.swift
//  MindMap
//
//  Created by Alina on 06.11.2021.
//

import UIKit

class MapViewController: UIViewController {
    
    // MARK: Stored properties
    var rootNode: Node?
    var rootNodeName: String?
    
    var nodeViews = [NodeView]()
    
    var lastNode: Node?
    
    // MARK: Outlet properties
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var contentViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentViewWidthConstraint: NSLayoutConstraint!
    
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
    }
    
    // MARK: Functions
    func configureUI() {
        center()
        
        // adding root node view
        addRootNode()
    }
    
    func center() {
        self.view.layoutIfNeeded()
        
        let centerOffsetX = (scrollView.contentSize.width - scrollView.frame.size.width) / 2
        let centerOffsetY = (scrollView.contentSize.height - scrollView.frame.size.height) / 2
        let centerPoint = CGPoint(x: centerOffsetX, y: centerOffsetY)
        scrollView.setContentOffset(centerPoint, animated: true)
    }
    
    func addRootNode() {
        if let rootNodeName = rootNodeName {
            // create node view
            let rootNodeView = NodeView(frame: CGRect(x: 0, y: 0, width: 0, height: 0), name: rootNodeName)
            rootNodeView.translatesAutoresizingMaskIntoConstraints = false
            
            contentView.addSubview(rootNodeView)
            rootNodeView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 0).isActive = true
            rootNodeView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 0).isActive = true
            
            nodeViews.append(rootNodeView)
            
            // init root node
            rootNode = Node(name: rootNodeName, nodeView: rootNodeView)
            lastNode = rootNode
            
            // init & add Swipe Gesture Recognizer
            if let rootNode = rootNode {
                addGestureRecognizer(node: rootNode, nodeView: rootNodeView)
            }
        }
    }
    
    func addChildNode(parentNode: Node, parentNodeView: NodeView, translation: CGPoint) {
        // create node view
        let strings = ["Lorem", "ipsum 🌚", "dolor", "sit amet, consectetur", "adipiscing🔥", "eiusmod tempor incididunt", "ut labore", "elit"]
        let randomName = strings.randomElement()!
        let childNodeView = NodeView(frame: CGRect(x: 0, y: 0, width: 0, height: 0), name: randomName)
        
        childNodeView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(childNodeView)
        
        childNodeView.centerXAnchor.constraint(equalTo: parentNodeView.centerXAnchor, constant: translation.x).isActive = true
        childNodeView.centerYAnchor.constraint(equalTo: parentNodeView.centerYAnchor, constant: translation.y).isActive = true
        
        nodeViews.append(childNodeView)
        
        // add node to a tree
        let childNode = Node(name: randomName, nodeView: childNodeView)
        parentNode.add(child: childNode)
        lastNode = childNode
        
        // init & add Swipe Gesture Recognizer
        addGestureRecognizer(node: childNode, nodeView: childNodeView)
        
        
        // draw line
        let line = LineView(parentView: parentNodeView, childView: childNodeView)
        contentView.insertSubview(line, at: 0)
        childNodeView.lines.append(line)
        parentNodeView.lines.append(line)
        line.updateFrame()
    }
    
    func addGestureRecognizer(node: Node, nodeView: NodeView) {
        let panGestureRecognizer = NodeCustomPanGesture(target: self, action: #selector(didPan(_:)))
        panGestureRecognizer.node = node
        panGestureRecognizer.nodeView = nodeView
        nodeView.addGestureRecognizer(panGestureRecognizer)
        
        let pan = NodeCustomPanGesture(target: self, action: #selector(twoFingerPan(_:)))
        pan.node = node
        pan.nodeView = nodeView
        pan.minimumNumberOfTouches = 2
        pan.maximumNumberOfTouches = 2
        pan.delaysTouchesBegan = true
        nodeView.addGestureRecognizer(pan)
    }
    
    // MARK: - Actions
    @objc func twoFingerPan(_ gesture: NodeCustomPanGesture) {
        if let nodeView = gesture.nodeView {
            switch gesture.state {
            case .began:
                nodeView.superview?.bringSubviewToFront(nodeView)
//                scrollView.isScrollEnabled = false
            case .changed:
                // TODO: Move view and render line views
                nodeView.center = gesture.location(in: nodeView.superview)
                for line in nodeView.lines {
                    line.updateFrame()
                }
            case .cancelled, .ended, .failed:
//                scrollView.isScrollEnabled = true
                break
            default:
                break
            }
        }
        print("2 Fingers!")
    }
    
    @objc private func didPan(_ sender: NodeCustomPanGesture) {
        switch sender.state {
        case .began:
            break
            
        case .changed:
            let originX = contentView.frame.origin.x
            let originY = contentView.frame.origin.y
            let width = contentView.frame.size.width
            let height = contentView.frame.size.height
            
            let deltaWidth = sender.translation(in: contentView).x
            let deltaHeight = sender.translation(in: contentView).y
            
            // expand contentView to the right
            if UIScreen.main.bounds.width - sender.location(in: view).x <= 70 {
                //                contentView.frame = CGRect(x: originX + deltaWidth, y: originY + deltaHeight, width: width - deltaWidth, height: height - deltaHeight)
                
                contentViewWidthConstraint.constant = width + 10
                contentView.layoutIfNeeded()
                
            }
            
            if sender.location(in: view).x <= 70 {
                print("Expand content to left")
                scrollView.setContentOffset(CGPoint(x: 150, y: 0), animated: true)
            }
            
            if UIScreen.main.bounds.height - sender.location(in: view).y <= 70 {
                print("Expand content to bottom")
            }
            
            if sender.location(in: view).y <= 70 {
                print("Expand content to top")
            }
            
            break
        case .ended:
            //            print("Touch ended at \(sender.translation(in: contentView))")
            //            print(sender.nodeView?.bounds.width, sender.nodeView?.bounds.height, sender.nodeView?.frame.midX, sender.nodeView?.frame.midY)
            
            
            
            // TODO: check if new node covering any other node
            
            // adding line between nodes
            if let parentNode = sender.node, let parentNodeView = sender.nodeView {
                let parentCenter = CGPoint(x: parentNodeView.frame.midX, y: parentNodeView.frame.midY)
                let translation = sender.translation(in: contentView)
                
                addChildNode(parentNode: parentNode, parentNodeView: parentNodeView, translation: translation)
                
                
                
                //                drawLine(parentCenter: parentCenter, childCenter: CGPoint(x: parentCenter.x + translation.x, y: parentCenter.y + translation.y))
                
                contentView.bringSubviewToFront(parentNodeView)
                if let lastAddedView = nodeViews.last {
                    contentView.bringSubviewToFront(lastAddedView)
                }
            }
            
            contentView.setNeedsDisplay()
            
            //            self.view.layoutIfNeeded()
            //
            //            let centerOffsetX = (scrollView.contentSize.width - scrollView.frame.size.width) / 2
            //            let centerOffsetY = (scrollView.contentSize.height - scrollView.frame.size.height) / 2
            //            let centerPoint = CGPoint(x: centerOffsetX, y: centerOffsetY)
            //            scrollView.setContentOffset(centerPoint, animated: true)
            
        case .cancelled:
            print("Touch cancelled")
        default:
            break
        }
    }
    
    func drawLine(parentCenter: CGPoint, childCenter: CGPoint) {
        let path = UIBezierPath()
        path.move(to: parentCenter)
        let halfOfViewWidth = (childCenter.x - parentCenter.x) / 2
        let point1 = CGPoint(x: parentCenter.x + halfOfViewWidth, y: parentCenter.y)
        let point2 = CGPoint(x: childCenter.x - halfOfViewWidth, y: childCenter.y)
        path.addCurve(to: childCenter, controlPoint1: point1, controlPoint2: point2)
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = getColorByDepth().cgColor
        shapeLayer.lineWidth = 1.5
        
        contentView.layer.addSublayer(shapeLayer)
    }
    
    func getColorByDepth() -> UIColor {
        if let lastNode = lastNode, let depth = rootNode?.depthOfNode(id: lastNode.id), depth <= 4 {
            let r = (255.0 - Double(depth) * 36.0) / 255.0
            let g = (255.0 - Double(depth) * 42.0) / 255.0
            let b = (255.0 - Double(depth) * 13.0) / 255.0
            return UIColor(red: r, green: g, blue: b, alpha: 1.0)
        } else {
            return UIColor(red: 73 / 255, green: 41 / 255, blue: 187 / 255, alpha: 1.0)
        }
    }
    
    
}

