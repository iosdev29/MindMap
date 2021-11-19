import Foundation

import UIKit

protocol MapScrollViewDelegate: AnyObject {
    func presentAlert(mapFile: MapFile)
}

class MapScrollView: UIScrollView {
    
    // MARK: Stored properties
    var rootNode: Node?
    var rootNodeName: String?
    var mapFile: MapFile?
    var state: MapState?
    var nodeViews = [NodeView]()
    var lastNode: Node?
    
    weak var mapDelegate: MapScrollViewDelegate?
    private let fileStorage = FileStorage()
    
    var containerView: UIView!
    
    lazy var zoomingTap: UITapGestureRecognizer = {
        let zoomingTap = UITapGestureRecognizer(target: self, action: #selector(handleZoomingTap))
        zoomingTap.numberOfTapsRequired = 2
        return zoomingTap
    }()
    
    //MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.backgroundLight
        self.delegate = self
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.decelerationRate = UIScrollView.DecelerationRate.fast
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(viewSize: CGSize) {
        containerView?.removeFromSuperview()
        containerView = nil
        containerView = UIView()
        var newFrame = containerView.frame
        newFrame.size.width = viewSize.width
        newFrame.size.height = viewSize.height
        containerView.frame = newFrame
        
        self.addSubview(containerView)
        containerView.backgroundColor = UIColor.backgroundLight
        
        self.contentSize = viewSize
        
        self.minimumZoomScale = 0.5
        self.maximumZoomScale = 2.0
        self.zoomScale = 1.0
        
        self.containerView.addGestureRecognizer(self.zoomingTap)
        self.containerView.isUserInteractionEnabled = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.center()
    }
    
    func center() {
        let boundsSize = self.bounds.size
        var frameToCenter = containerView.frame
        
        if frameToCenter.size.width < boundsSize.width {
            frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2
        } else {
            frameToCenter.origin.x = 0
        }
        
        if frameToCenter.size.height < boundsSize.height {
            frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2
        } else {
            frameToCenter.origin.y = 0
        }
        
        containerView.frame = frameToCenter
    }
    
    // gesture
    @objc func handleZoomingTap(sender: UITapGestureRecognizer) {
        let location = sender.location(in: sender.view)
        
        let currectScale = self.zoomScale
        let minScale = self.minimumZoomScale
        let maxScale = self.maximumZoomScale
        
        if minScale == maxScale && minScale > 1 {
            return
        }
        
        let finalScale = currectScale == minScale ? maxScale : minScale
        self.zoom(to: zoomRect(scale: finalScale, center: location), animated: true)
    }
    
    
    func zoomRect(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        let bounds = self.bounds
        
        zoomRect.size.width = bounds.size.width / scale
        zoomRect.size.height = bounds.size.height / scale
        
        zoomRect.origin.x = center.x - (zoomRect.size.width / 2)
        zoomRect.origin.y = center.y - (zoomRect.size.height / 2)
        return zoomRect
    }
    
    func configureUI(rootNodeName: String) {
        self.rootNodeName = rootNodeName
        let defaultHeight = 2000.0
        let defaultWidth = 2000.0
        setup(viewSize: CGSize(width: defaultWidth, height: defaultHeight))
        self.state = .regular
        let _ = self.addRootNode(at: CGPoint(x: defaultWidth / 2, y: defaultHeight / 2))
        
        self.layoutIfNeeded()
        
        let centerOffsetX = (contentSize.width - frame.size.width) / 2
        let centerOffsetY = (contentSize.height - frame.size.height) / 2
        let centerPoint = CGPoint(x: centerOffsetX, y: centerOffsetY)
        setContentOffset(centerPoint, animated: true)
    }
    
    func configureUI(viewSize: CGSize, mapFile: MapFile) {
        setup(viewSize: viewSize)
       
        var newFrame = containerView.frame
        newFrame.size.width = mapFile.contentViewSize.width
        newFrame.size.height = mapFile.contentViewSize.height
        containerView.frame = newFrame
        
        self.state = mapFile.state
        self.mapFile = mapFile
        
        // TODO: Start Activity indicator
        self.rootNodeName = mapFile.rootNode.name
        self.rootNode = mapFile.rootNode
        if let centerPosition = mapFile.rootNode.centerPosition {
            if let rootV = self.addRootNode(at: centerPosition) {
                let _ = self.addChildUI(node: mapFile.rootNode, parentView: rootV)
            }
        }
        // TODO: Stop Activity indicator

        self.layoutIfNeeded()
        
        let centerOffsetX = (contentSize.width - frame.size.width) / 2
        let centerOffsetY = (contentSize.height - frame.size.height) / 2
        let centerPoint = CGPoint(x: centerOffsetX, y: centerOffsetY)
        setContentOffset(centerPoint, animated: true)
    }
    
    func addChildUI(node: Node, parentView: NodeView) -> NodeView? {
        if !node.children.isEmpty {
            node.children.forEach { child in
                if let x = addNodeExternally(parentNodeView: parentView, at: child.centerPosition ?? containerView.center, childNode: child) {
                    let _ = addChildUI(node: child, parentView: x)
                }
            }
        }
        return nil
    }
    
    func addRootNode(at location: CGPoint) -> NodeView? {
        if let rootNodeName = rootNodeName {
            // init root node
            if mapFile == nil {
                rootNode = Node(name: rootNodeName)
            }
            
            lastNode = rootNode
            
            if let rootNode = rootNode {
                // create node view
                let rootNodeView = NodeView(at: location, name: rootNodeName, node: rootNode, isRoot: true)
                rootNodeView.delegate = self
                containerView.addSubview(rootNodeView)
                nodeViews.append(rootNodeView)
                if mapFile == nil {
                    rootNode.centerPosition = rootNodeView.center
                } else {
                    rootNode.centerPosition = CGPoint(x: location.x, y: location.y)
                }
                return rootNodeView
            }
            
            saveMap()
            
        }
        return nil
    }
    
    func getColorByDepth() -> UIColor {
        if let lastNode = lastNode, let depth = rootNode?.depthOfNode(id: lastNode.id), depth <= 4 {
            let r = (255.0 - Double(depth) * 36.0) / 255.0
            let g = (255.0 - Double(depth) * 42.0) / 255.0
            let b = (255.0 - Double(depth) * 13.0) / 255.0
            return UIColor(red: r, green: g, blue: b, alpha: 1.0)
        } else {
            return UIColor.accentViolet
        }
    }

}


// MARK: NodeViewDelegate
extension MapScrollView: NodeViewDelegate {
    
    // expand VIew
    func expandView(direction: Direction) {
        let step = 50.0
        let width = containerView.frame.size.width
        let height = containerView.frame.size.height
        
        switch direction {
        case .top:
            var newFrame = containerView.frame
            newFrame.size.height = height + step
            containerView.frame = newFrame
            containerView.subviews.forEach { $0.frame.origin.y += step / 2 }
            
        case .bottom:
            var newFrame = containerView.frame
            newFrame.size.height = height + step
            containerView.frame = newFrame
            
        case .left:
            var newFrame = containerView.frame
            newFrame.size.width = width + step
            containerView.frame = newFrame
            containerView.subviews.forEach { $0.frame.origin.x += step / 2 }
            
        case .right:
            var newFrame = containerView.frame
            newFrame.size.width = width + step
            containerView.frame = newFrame
        }
        containerView.layoutIfNeeded()
    }
    
    // delete views and nodes
    func delete(view: NodeView) {
        if let node = view.node, let rootNode = rootNode {
            if node == rootNode {
                showDeletingAlert()
            } else {
                var deletedIds = [UUID]()
                node.forEachDepthFirst { deletedIds.append($0.id) }
                rootNode.remove(node: node)
                nodeViews.forEach { nodeView in
                    if let nodeToDelete = nodeView.node, deletedIds.contains(nodeToDelete.id) {
                        nodeView.delete()
                    }
                }
            }
            saveMap()
        }
    }
    
    // deleted root node -> deleting all map
    func showDeletingAlert() {
        if let mapFile = mapFile {
            mapDelegate?.presentAlert(mapFile: mapFile)
        }
    }
    
    func didEditText(view: NodeView, text: String) {
        // saving new node's name
        if let id = view.node?.id, let rootNode = rootNode, let searchedNode = rootNode.search(id: id) {
            searchedNode.name = text
        }
        saveMap()
    }
    
    func addChildNode(parentNodeView: NodeView, at location: CGPoint) {
        if let parentNode = parentNodeView.node  {
            // add node to a tree
            let childNode = Node(name: "")
            parentNode.add(child: childNode)
            lastNode = childNode
            let _ = drawNode(parentNodeView: parentNodeView, at: location, childNode: childNode, externally: false)
        }
    }
    
    func addNodeExternally(parentNodeView: NodeView, at location: CGPoint, childNode: Node) -> NodeView? {
        // add node to a tree
        lastNode = childNode
        return drawNode(parentNodeView: parentNodeView, at: location, childNode: childNode, externally: true)
    }
    
    func drawNode(parentNodeView: NodeView, at location: CGPoint, childNode: Node, externally: Bool) -> NodeView? {
        let childNodeView = NodeView(at: location, name: childNode.name, node: childNode, isRoot: false)
        
        // add node view
        if !externally {
            childNodeView.textView.becomeFirstResponder()
        }
        
        childNodeView.delegate = self
        self.containerView.addSubview(childNodeView)
        self.nodeViews.append(childNodeView)
        
        // draw spline
        let spline = SplineView(parentView: parentNodeView, childView: childNodeView, color: self.getColorByDepth())
        self.containerView.insertSubview(spline, at: 0)
        parentNodeView.splines.append(spline)
        childNodeView.splines.append(spline)
        spline.update()
        childNode.centerPosition = childNodeView.center
        saveMap()
        
        return childNodeView
    }
    
    //MARK: - Saving Map
    func saveMap() {
        let screen = image(with: containerView) ?? UIColor.backgroundLight.image()
        if let name = rootNode?.name {
            do {
                try saveMapImagePreview(image: screen, name: name)
                try saveMapFile(image: screen, name: name)
            } catch {
                ErrorReporting.showMessage(title: "Error", message: "Wasn't able to save map")
            }
        }
    }
    
    func image(with view: UIView) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.isOpaque, 0.0)
        defer { UIGraphicsEndImageContext() }
        if let context = UIGraphicsGetCurrentContext() {
            view.layer.render(in: context)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            return image
        }
        return UIColor.backgroundLight.image()
    }
    
    func saveMapImagePreview(image: UIImage, name: String) throws {
        guard let data = image.jpegData(compressionQuality: 1) ?? image.pngData() else { return }
        try self.fileStorage.writeFile(data, atPath: "\(name)\(String.pngExtension)")
    }
    
    func saveMapFile(image: UIImage, name: String) throws {
        if let rootNode = rootNode, let state = state {
            let mapFile = MapFile(image: image, rootNode: rootNode, contentViewSize: CGSize(width: containerView.frame.width, height: containerView.frame.height), state: state)
            self.mapFile = mapFile
            let encodedMapFile = try JSONEncoder().encode(mapFile)
            try fileStorage.writeFile(encodedMapFile, atPath: "\(name)\(String.mmdExtension)")
        }
    }
    
    //MARK: - Preview for Home, Stolen from https://stackoverflow.com/questions/41308685/screenshot-on-swift-programmatically
    static func screenshot() -> UIImage {
        let imageSize = UIScreen.main.bounds.size as CGSize;
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
        let context = UIGraphicsGetCurrentContext()
        for obj : AnyObject in UIApplication.shared.windows {
            if let window = obj as? UIWindow {
                if window.responds(to: #selector(getter: UIWindow.screen)) || window.screen == UIScreen.main {
                    context!.saveGState()
                    context!.translateBy(x: window.center.x, y: window.center.y)
                    context!.concatenate(window.transform)
                    context!.translateBy(x: -window.bounds.size.width * window.layer.anchorPoint.x, y: -window.bounds.size.height * window.layer.anchorPoint.y)
                    window.layer.render(in: context!)
                    context!.restoreGState();
                }
            }
        }
        return UIGraphicsGetImageFromCurrentImageContext()!
    }
}

// MARK: - UIScrollViewDelegate
extension MapScrollView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.containerView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        self.center()
    }
}
