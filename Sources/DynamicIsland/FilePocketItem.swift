import Foundation
import AppKit

public struct FilePocketItem: Identifiable, Hashable {
    public let id = UUID()
    public let url: URL
    public let name: String
    public let sizeFormatted: String
    public let dateAdded: Date
    
    public init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        self.dateAdded = Date()
        
        if let resources = try? url.resourceValues(forKeys: [.fileSizeKey]),
           let size = resources.fileSize {
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            self.sizeFormatted = formatter.string(fromByteCount: Int64(size))
        } else {
            self.sizeFormatted = "--"
        }
    }
    
    public var icon: NSImage {
        NSWorkspace.shared.icon(forFile: url.path)
    }
    
    public func open() {
        NSWorkspace.shared.open(url)
    }
    
    public func revealInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
