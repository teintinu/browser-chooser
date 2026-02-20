import Foundation

struct BrowserRule: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String        // Friendly name (e.g., "Google Chrome")
    var bundleId: String    // Bundle Identifier (e.g., "com.google.Chrome")
    var pattern: String     // Regular Expression String

    init(id: UUID = UUID(), name: String, bundleId: String, pattern: String) {
        self.id = id
        self.name = name
        self.bundleId = bundleId
        self.pattern = pattern
    }
}

struct InstalledBrowser: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let bundleId: String
    let path: URL?
}
