import Foundation

class FileStorage {
    
    // MARK: Stored properties
    private let fileManager: FileManager
    
    // MARK: Initialize
    init(fileManager: FileManager = FileManager.default) {
        self.fileManager = fileManager
    }
    
    // MARK: Functions
    func documentDirectoryPath(_ appendingPath: String) -> URL {
        guard let url = self.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("\(#function) `documentDirectory` not found")
        }
        return url.appendingPathComponent(appendingPath)
    }
    
    func getFile(atPath path: String) throws -> Data {
        let url = self.documentDirectoryPath(path)
        return try Data(contentsOf: url, options: .mappedIfSafe)
    }
    
    func writeFile(_ data: Data, atPath path: String) throws {
        let url = self.documentDirectoryPath(path)
        try data.write(to: url)
    }
    
    func deleteFile(atPath path: String) throws {
        let url = self.documentDirectoryPath(path)
        try self.fileManager.removeItem(at: url)
    }
    
    func copyFile(at url: URL) throws -> MapFile {
        let encodedMapFile = try Data(contentsOf: url, options: .mappedIfSafe)
        // import file
        let mapData = try JSONDecoder().decode(MapFile.self, from: encodedMapFile)
        try writeFile(encodedMapFile, atPath: "\(mapData.rootNode.name)\(String.mmdExtension)")
        return mapData
    }
    
    func getAllFiles(with type: String) -> [String] {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        if let urlArray = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey], options:.skipsHiddenFiles) {
            return urlArray.map { url in
                (url.lastPathComponent, (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast)
            }.filter({ $0.0.hasSuffix(type)}).map { $0.0 }
        } else {
            return [String]()
        }
    }
    
    func getRecentFiles(with type: String) -> [String] {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        if let urlArray = try? FileManager.default.contentsOfDirectory(at: directory,includingPropertiesForKeys: [.contentModificationDateKey], options:.skipsHiddenFiles) {
            return urlArray.map { url in
                (url.lastPathComponent, (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast)
            }.filter({ $0.0.hasSuffix(type)})
                .sorted(by: { $0.1 > $1.1 })
                .map { $0.0 }
        } else {
            return [String]()
        }
    }
    
}
