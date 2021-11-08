//
//  NodeView.swift
//  MindMap
//
//  Created by Alina on 06.11.2021.
//

import UIKit

class NodeView: UIView {
    let kCONTENT_XIB_NAME = "NodeView"
    var lines = [LineView]()

    
    let viewheight: CGFloat = 80
    let minWidth: CGFloat = 80
    let maxWidth: CGFloat = 240
    let padding: CGFloat = 16
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    
    init(frame: CGRect, name: String) {
        super.init(frame: frame)
        
        Bundle.main.loadNibNamed(kCONTENT_XIB_NAME, owner: self, options: nil)

        configureUI(name: name)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureUI(name: String) {
        nameLabel.text = name
        nameLabel.preferredMaxLayoutWidth = 120
        
        // adding shadow
        contentView.layer.shadowColor = UIColor.white.cgColor
        contentView.layer.shadowOpacity = 0.5
        contentView.layer.shadowOffset = .zero
        contentView.layer.shadowRadius = 4
        setupConstraints()
        update()
        
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(didPan(gesture:))))
    }
    
    func setupConstraints() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(contentView)
        
        contentView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
    }
    
    func update() {
        // Calculate frame for text and call draw
        let textSize = nameLabel.sizeThatFits(CGSize(width: maxWidth-2*padding, height: viewheight-2*padding))
        let width = max(minWidth, textSize.width + 2 * padding)
        nameLabel.frame = CGRect(x: padding, y: padding, width: width-2*padding, height: viewheight-2*padding)
        frame = CGRect(x: center.x-width/2, y: frame.origin.y, width: width, height: viewheight)
    }
    
    @objc func didPan(gesture:UIPanGestureRecognizer) {
        if gesture.state == .changed {
            // TODO: Move view and render line views
            self.center = gesture.location(in: self.superview)
            for line in lines {
                line.updateFrame()
            }
        } else if gesture.state == .began {
            superview?.bringSubviewToFront(self)
        }
    }
}

