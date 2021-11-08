//
//  Node.swift
//  MindMap
//
//  Created by Alina on 06.11.2021.
//

import Foundation
import UIKit

class Node: NSObject {
    var id = UUID()
    var name: String
    var nodeView: NodeView
    
    private (set) var children: [Node] = []
    weak var parent: Node?
    
    override var description: String {
        var text = "\(name)"
        if !children.isEmpty {
            text += " {" + children.map { $0.description }.joined(separator: ", ") + "} "
        }
        return text
    }
    
    init(name: String, nodeView: NodeView) {
        self.name = name
        self.nodeView = nodeView
    }
    
    func add(child: Node) {
        children.append(child)
        child.parent = self
    }
    
    func search(id: UUID) -> Node? {
        if id == self.id {
            return self
        }
        for child in children {
            if let found = child.search(id: id) {
                return found
            }
        }
        return nil
    }
    
    func remove(node: Node) {
        if let nodeToDelete = search(id: node.id) {
            if let parentNodeToDelete = nodeToDelete.parent {
                parentNodeToDelete.children.removeAll(where: { childNode in
                    nodeToDelete == childNode
                })
            } else {
                print("Are you sure to delete all the nodes?")
            }
        } else {
            print("This node doesn't exist")
        }
    }
    
    func depthOfNode(id: UUID) -> Int {
        var result = 0
        var node = search(id: id)
        
        while node?.parent != nil  {
            result += 1
            node = node?.parent
        }
        
        return result
    }
    
}
