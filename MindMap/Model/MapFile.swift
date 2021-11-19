import UIKit

struct MapFile: Codable {
    var image: UIImage
    var rootNode: Node
    var contentViewSize: CGSize
    var state: MapState
    
    enum CodingKeys: String, CodingKey {
        case image, rootNode, contentViewSize, state
    }
    
    init(image: UIImage, rootNode: Node, contentViewSize: CGSize, state: MapState) {
        self.image = image
        self.rootNode = rootNode
        self.contentViewSize = contentViewSize
        self.state = state
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        rootNode = try values.decode(Node.self, forKey: .rootNode)
        contentViewSize = try values.decode(CGSize.self, forKey: .contentViewSize)
        state = try values.decode(MapState.self, forKey: .state)
        let data = try values.decode(Data.self, forKey: .image)
        guard let image = UIImage(data: data) else {
            throw DecodingError.dataCorruptedError(forKey: .image, in: values, debugDescription: "Invalid image data")
        }
        self.image = image
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(rootNode, forKey: .rootNode)
        try container.encode(contentViewSize, forKey: .contentViewSize)
        try container.encode(state, forKey: .state)
        try container.encode(image.pngData(), forKey: .image)
    }
}
