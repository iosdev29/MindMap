//
//  MegaView.swift
//  Mega Mindmap
//
//  Created by Markus Karlsson on 2019-04-10.
//  Copyright © 2019 The App Factory AB. All rights reserved.
//

import UIKit

enum Direction {
    case top
    case bottom
    case left
    case right
}

protocol NodeViewDelegate {
    func addChildNode(parentNodeView: NodeView, at location: CGPoint)
    func didEditText(view: NodeView, text: String)
    func delete(view: NodeView)
    func expandView(direction: Direction)
}

class NodeView: UIView {
    // MARK: Stored properties
    var delegate: NodeViewDelegate?
    var splines = [SplineView]()
    var node: Node?
    var isRoot: Bool?
    
    let viewHeight: CGFloat = 120
    let minWidth: CGFloat = 120
    let maxWidth: CGFloat = 350
    let padding: CGFloat = 16
    
    lazy var textView: UITextView = {
        let label = UITextView()
        label.textAlignment = NSTextAlignment.center
        label.textColor = .lightGray
        label.text = "Type your idea here..."
        label.isEditable = true
        label.textColor = UIColor.white
        label.delegate = self
        label.backgroundColor = .clear
        label.font = .systemFont(ofSize: 16)
        label.autocorrectionType = .no
        return label
    }()
    
    // MARK: Initialize
    init(at position: CGPoint, name: String, node: Node, isRoot: Bool) {
        let size: CGFloat = 120
        let frame = CGRect(x: position.x - size / 2, y: position.y - size / 2, width: size, height: size)
        super.init(frame: frame)
        
        textView.frame = self.bounds
        textView.text = name
        addSubview(textView)
        
        self.node = node
        self.isRoot = isRoot
        
        // adding shadow
        layer.shadowColor = UIColor.white.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = .zero
        layer.shadowRadius = 4
        
        backgroundColor = UIColor.clear
        
        // adding child
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(didPan(gesture:))))
        
        // moving view
        let pan = UIPanGestureRecognizer(target: self, action: #selector(twoFingerPan(_:)))
        pan.minimumNumberOfTouches = 2
        pan.maximumNumberOfTouches = 2
        pan.delaysTouchesBegan = true
        addGestureRecognizer(pan)
        
        // contextMenu (editing + removing)
        let interaction = UIContextMenuInteraction(delegate: self)
        self.addInteraction(interaction)
        
        update()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    //MARK: - Functions
    func delete() {
        DispatchQueue.main.async {
            self.splines.forEach({ $0.removeFromSuperview() })
            self.removeFromSuperview()
        }
    }
    
    func update() {
        let textSize = textView.sizeThatFits(CGSize(width: maxWidth - 2 * padding, height: viewHeight - 2 * padding))
        let width = max(minWidth, textSize.width + 2 * padding)
        
        let labelSize = textView.getSize(constrainedWidth: width)
        
        textView.frame = CGRect(x: padding, y: padding, width: width - 2 * padding, height: labelSize.height )
        frame = CGRect(x: center.x - width / 2, y: frame.origin.y, width: width, height: labelSize.height + 2 * padding)
        
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: [.allCorners], cornerRadii: CGSize(width: 8, height: 8))
        UIColor.backgroundViolet.setFill()
        path.fill()
    }
    
    @objc func didPan(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case.changed:
            if let contentView = superview {
                needsExpand(location: gesture.location(in: contentView))
            }
        case .ended:
            delegate?.addChildNode(parentNodeView: self, at: gesture.location(in: self.superview))
        default:
            break
        }
    }
    
    @objc func twoFingerPan(_ gesture: UIPanGestureRecognizer) {
        // moving view & splines
        switch gesture.state {
        case .changed:
            self.center = gesture.location(in: self.superview)
            splines.forEach({ $0.update() })
            if let contentView = superview {
                needsExpand(location: gesture.location(in: contentView))
            }
        case .began:
            superview?.bringSubviewToFront(self)
        default:
            break
        }
    }
    
    func needsExpand(location: CGPoint) {
        if let contentView = superview {
            if contentView.frame.width - location.x <= 100 {
                delegate?.expandView(direction: .right)
            }
            
            if location.x <= 100 {
                delegate?.expandView(direction: .left)
            }
            
            if contentView.frame.height - location.y <= 100 {
                delegate?.expandView(direction: .bottom)
            }
            
            if location.y <= 100 {
                delegate?.expandView(direction: .top)
            }
        }
    }
}

//MARK: - UIContextMenuInteractionDelegate
extension NodeView: UIContextMenuInteractionDelegate {
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        let removeIcon = UIImage(named: "delete")
        let editIcon = UIImage(named: "edit")
        
        return UIContextMenuConfiguration(identifier: "id" as NSCopying, previewProvider: nil, actionProvider: { _ in
            let editAction = UIAction(title: "Edit", image: editIcon, identifier: nil, discoverabilityTitle: nil) { _ in
                self.textView.becomeFirstResponder()
            }
            
            let removeAction = UIAction(title: "Remove", image: removeIcon, identifier: nil, discoverabilityTitle: nil, attributes: .destructive, handler: { _ in
                self.delegate?.delete(view: self)
            })
            
            return UIMenu(title: "Edit", image: nil, options: [.displayInline], children: [editAction, removeAction])
        })
    }
    
    
    //MARK: - Stolen from https://kylebashour.com/posts/context-menu-guide
    // improved UI behaviour
    private func makeTargetedPreview(for configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        let visiblePath = UIBezierPath(roundedRect: self.bounds, cornerRadius: 16)
        let parameters = UIPreviewParameters()
        parameters.visiblePath = visiblePath
        parameters.backgroundColor = .clear
        return UITargetedPreview(view: self, parameters: parameters)
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return self.makeTargetedPreview(for: configuration)
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForDismissingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return self.makeTargetedPreview(for: configuration)
    }
}

//MARK: - UITextViewDelegate
extension NodeView: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor != .white && textView.isFirstResponder {
            textView.text = nil
            textView.textColor = .white
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty || textView.text == "" {
            textView.textColor = .lightGray
            textView.text = "Type your idea here..."
        }
        update()
        delegate?.didEditText(view: self, text: textView.text)
    }
}
