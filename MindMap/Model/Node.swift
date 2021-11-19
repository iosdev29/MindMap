import Foundation
import UIKit

class Node: NSObject, Codable {
    // MARK: Stored properties
    let id = UUID()
    var name: String
    var centerPosition: CGPoint?
    
    private (set) var children: [Node] = []
    weak var parent: Node?
    
    override var description: String {
        var text = "\(name)"
        if !children.isEmpty {
            text += " [" + children.map { $0.description }.joined(separator: ", ") + "] "
        }
        return text
    }
    
    // MARK: Initialize
    init(name: String) {
        self.name = name
    }
    
    // MARK: Methods
    func add(child: Node) {
        children.append(child)
        child.parent = self
    }
    
    func search(id: UUID) -> Node? {
        if let n = self.children.filter({ $0.id == id}).first {
            return n
        }
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
        if let nodeToDelete = search(id: node.id), let parentNodeToDelete = nodeToDelete.parent {
            parentNodeToDelete.children.removeAll(where: { childNode in
                nodeToDelete == childNode
            })
        }
    }
    
    func depthOfNode(id: UUID) -> Int {
        var result = 0
        var node = search(id: id)
        
        while node?.parent != nil  {
            result += 2
            node = node?.parent
        }
        return result
    }
    
    func forEachDepthFirst(visit: (Node) -> Void) {
        visit(self)
        children.forEach { $0.forEachDepthFirst(visit: visit) }
    }
    
    //MARK: - Codable
    private enum CodingKeys: String, CodingKey {
        case name
        case children
        case centerPosition
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(centerPosition, forKey: .centerPosition)
        if !children.isEmpty {
            try container.encode(children, forKey: .children)
        } else {
            try container.encode([Node](), forKey: .children)
        }
    }
}
