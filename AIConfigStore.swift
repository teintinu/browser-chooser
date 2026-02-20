import Foundation

struct AIConfig: Codable {
    var baseURL: String
    var apiKey: String?
    var model: String
    
    static let `default` = AIConfig(baseURL: "http://localhost:33333", apiKey: "", model: "gpt-4o-mini")
}

class AIConfigStore: ObservableObject {
    static let shared = AIConfigStore()
    
    @Published var config: AIConfig = .default {
        didSet {
            save()
        }
    }
    
    private let fileManager = FileManager.default
    private var configURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = appSupport.appendingPathComponent("teintinu-browser-chooser")
        
        if !fileManager.fileExists(atPath: folder.path) {
            try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        
        return folder.appendingPathComponent("config.json")
    }
    
    private init() {
        load()
    }
    
    func load() {
        guard fileManager.fileExists(atPath: configURL.path) else {
            self.config = .default
            return
        }
        
        do {
            let data = try Data(contentsOf: configURL)
            self.config = try JSONDecoder().decode(AIConfig.self, from: data)
        } catch {
            print("Error loading config: \(error)")
            self.config = .default
        }
    }
    
    func save() {
        do {
            let data = try JSONEncoder().encode(config)
            try data.write(to: configURL)
        } catch {
            print("Error saving config: \(error)")
        }
    }
}
