import Foundation

class RulesStore: ObservableObject {
    static let shared = RulesStore()
    
    @Published var rules: [BrowserRule] = []
    
    private let fileManager = FileManager.default
    private var rulesURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = appSupport.appendingPathComponent("teintinu-browser-chooser")
        
        if !fileManager.fileExists(atPath: folder.path) {
            try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        
        return folder.appendingPathComponent("rules.json")
    }
    
    private init() {
        load()
    }
    
    func load() {
        guard fileManager.fileExists(atPath: rulesURL.path) else {
            self.rules = []
            return
        }
        
        do {
            let data = try Data(contentsOf: rulesURL)
            self.rules = try JSONDecoder().decode([BrowserRule].self, from: data)
        } catch {
            print("Error loading rules: \(error)")
            self.rules = []
        }
    }
    
    func save() {
        do {
            let data = try JSONEncoder().encode(rules)
            try data.write(to: rulesURL)
        } catch {
            print("Error saving rules: \(error)")
        }
    }
    
    func matchingRule(for url: URL) -> BrowserRule? {
        let urlString = url.absoluteString
        return rules.first { rule in
            guard let regex = try? NSRegularExpression(pattern: rule.pattern, options: []) else {
                return false
            }
            let range = NSRange(location: 0, length: urlString.utf16.count)
            return regex.firstMatch(in: urlString, options: [], range: range) != nil
        }
    }
    
    func add(rule: BrowserRule) {
        rules.append(rule)
        save()
    }
    
    func update(rule: BrowserRule) {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index] = rule
            save()
        }
    }
    
    func remove(rule: BrowserRule) {
        rules.removeAll(where: { $0.id == rule.id })
        save()
    }
}
