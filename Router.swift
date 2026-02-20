import AppKit
import Foundation
import Combine

class Router: ObservableObject {
    static let shared = Router()
    
    @Published var pendingURL: URL?
    @Published var isShowingPicker = false {
        didSet {
            if !isShowingPicker {
                pendingURL = nil
                isRouting = false
            } else {
                isRouting = true
            }
        }
    }
    
    var isRouting = false
    
    // List of common browsers to check
    private let commonBrowsers = [
        ("Safari", "com.apple.Safari"),
        ("Google Chrome", "com.google.Chrome"),
        ("Microsoft Edge", "com.microsoft.edgemac"),
        ("Comet", "ai.perplexity.Comet"),
        ("Firefox", "org.mozilla.firefox"),
        ("Vivaldi", "com.vivaldi.Vivaldi"),
        ("Brave", "com.brave.Browser"),
        ("Arc", "company.thebrowser.Browser")
    ]
    
    private init() {}
    
    func handle(url: URL) {
        if let rule = RulesStore.shared.matchingRule(for: url) {
            isRouting = true
            open(url: url, with: rule.bundleId)
        } else {
            DispatchQueue.main.async {
                self.pendingURL = url
                self.isShowingPicker = true
                
                // Ensure the app is active to show the picker
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    func open(url: URL, with bundleId: String) {
        let configuration = NSWorkspace.OpenConfiguration()
        
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: configuration) { _, error in
                if let error = error {
                    print("Error opening browser \(bundleId): \(error)")
                    // Fallback to default if error
                    NSWorkspace.shared.open(url)
                }
                
                // Terminate the app after forwarding the URL
                DispatchQueue.main.async {
                    NSApp.terminate(nil)
                }
            }
        } else {
            // Fallback to default if app not found
            NSWorkspace.shared.open(url)
            DispatchQueue.main.async {
                NSApp.terminate(nil)
            }
        }
    }
    
    func getInstalledBrowsers() -> [InstalledBrowser] {
        var installed: [InstalledBrowser] = []
        
        for (name, bundleId) in commonBrowsers {
            if let path = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                installed.append(InstalledBrowser(name: name, bundleId: bundleId, path: path))
            }
        }
        
        return installed
    }
    
    func createRuleFromSelection(url: URL, browser: InstalledBrowser) {
        Task {
            do {
                let patterns = try await AIClient.shared.suggestRegexes(for: url.absoluteString, browserName: browser.name)
                if let firstPattern = patterns.first {
                    let newRule = BrowserRule(name: browser.name, bundleId: browser.bundleId, pattern: firstPattern)
                    DispatchQueue.main.async {
                        RulesStore.shared.add(rule: newRule)
                    }
                }
            } catch {
                print("Failed to get AI suggestions: \(error)")
                // Just create a specific rule for this URL if AI fails
                let pattern = NSRegularExpression.escapedPattern(for: url.absoluteString)
                let newRule = BrowserRule(name: browser.name, bundleId: browser.bundleId, pattern: pattern)
                DispatchQueue.main.async {
                    RulesStore.shared.add(rule: newRule)
                }
            }
        }
    }
}
