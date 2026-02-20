import SwiftUI

struct BrowserPickerView: View {
    let url: URL
    @State private var browsers: [InstalledBrowser] = []
    @State private var selectedBrowser: InstalledBrowser?
    @State private var alwaysOpen = false
    @State private var isGeneratingPatterns = false
    @State private var suggestedPatterns: [String] = []
    @State private var selectedPattern: String = ""
    @State private var showPatternSelection = false
    @State private var showingSettingsSheet = false
    @State private var aiTask: Task<Void, Never>? = nil
    @AppStorage("lastSelectedBrowserBundleId") private var lastBrowserId: String = "com.apple.Safari"
    @State private var testUrl: String = ""
    
    private var isRegexValid: Bool {
        guard !selectedPattern.isEmpty else { return false }
        do {
            let regex = try NSRegularExpression(pattern: selectedPattern, options: [])
            let range = NSRange(location: 0, length: testUrl.utf16.count)
            return regex.firstMatch(in: testUrl, options: [], range: range) != nil
        } catch {
            return false
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if !showPatternSelection {
                pickerView
            } else {
                suggestionView
            }
        }
        .padding(24)
        .frame(width: 550, height: 600)
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsView()
                .frame(width: 400, height: 450)
                .padding()
        }
        .onAppear {
            browsers = Router.shared.getInstalledBrowsers()
            testUrl = url.absoluteString
            // Try to restore last selection, fallback to Safari or first available
            if let last = browsers.first(where: { $0.bundleId == lastBrowserId }) {
                selectedBrowser = last
            } else {
                selectedBrowser = browsers.first { $0.bundleId == "com.apple.Safari" } ?? browsers.first
            }
        }
    }
    
    var pickerView: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "safari.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading) {
                    Text("Where do you want to open?")
                        .font(.title3.bold())
                    Text(url.absoluteString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                
                Button {
                    showingSettingsSheet = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .help("Settings")
            }
            
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(browsers) { browser in
                        Button {
                            selectedBrowser = browser
                            lastBrowserId = browser.bundleId
                        } label: {
                            HStack {
                                Text(browser.name)
                                    .font(.body)
                                Spacer()
                                if selectedBrowser?.bundleId == browser.bundleId {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedBrowser?.bundleId == browser.bundleId ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedBrowser?.bundleId == browser.bundleId ? Color.accentColor : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Divider()
            
            Toggle(isOn: $alwaysOpen) {
                VStack(alignment: .leading) {
                    Text("Always open this type of link in this browser")
                        .font(.subheadline.bold())
                    Text("We will configure an automatic rule for you")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.checkbox)
            
            HStack {
                Button("Cancel") { Router.shared.isShowingPicker = false }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: handleOpen) {
                    Text(alwaysOpen ? "Configure Rule" : "Open with \(selectedBrowser?.name ?? "...")")
                        .frame(minWidth: 120)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(selectedBrowser == nil)
            }
        }
    }
    
    var suggestionView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Define Routing Rule")
                        .font(.title3.bold())
                    Text("The URL will be opened as soon as you confirm")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Button {
                    showingSettingsSheet = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .help("Settings")
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Your Regular Expression (Regex):")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                
                TextField("Edit Regex...", text: $selectedPattern)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.1)))
                    .font(.system(.body, design: .monospaced))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(selectedPattern.isEmpty ? Color.clear : (isRegexValid ? Color.green.opacity(0.5) : Color.red.opacity(0.5)), lineWidth: 2))
                
                if isGeneratingPatterns {
                    HStack(spacing: 8) {
                        ProgressView().controlSize(.small)
                        Text("Fetching AI suggestions using \(AIConfigStore.shared.config.model.split(separator: ":").first.map(String.init) ?? AIConfigStore.shared.config.model)...")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                    .padding(.top, 4)
                }
            }
            
            if !suggestedPatterns.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("AI Suggestions (Click to Apply):")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if !isGeneratingPatterns {
                            Button {
                                if let browser = selectedBrowser {
                                    startAITask(for: browser)
                                }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption)
                                    .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.plain)
                            .help("Refresh AI Suggestions")
                        }
                    }
                    
                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(suggestedPatterns, id: \.self) { pattern in
                                Button {
                                    selectedPattern = pattern
                                } label: {
                                    HStack {
                                        Text(pattern)
                                            .font(.system(.caption, design: .monospaced))
                                            .lineLimit(1)
                                        Spacer()
                                        Image(systemName: "doc.on.doc")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(selectedPattern == pattern ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.05))
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                }
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(testUrl == url.absoluteString ? "URL being opened:" : "Test URL:")
                        .font(.caption2.bold())
                        .foregroundColor(testUrl == url.absoluteString ? .secondary : .accentColor)
                    
                    Spacer()
                    
                    if testUrl != url.absoluteString {
                        Button {
                            testUrl = url.absoluteString
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset")
                            }
                            .font(.caption2.bold())
                            .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                TextField("URL to test regex...", text: $testUrl)
                    .font(.system(size: 10, design: .monospaced))
                    .textFieldStyle(.plain)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.05)))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(testUrl == url.absoluteString ? Color.clear : Color.accentColor.opacity(0.3), lineWidth: 1))
            }
            
            HStack {
                Button("Back") {
                    cancelAITask()
                    showPatternSelection = false
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                HStack(spacing: 12) {
                    if !selectedPattern.isEmpty {
                        Label(isRegexValid ? "Valid Regex" : "Invalid Regex", systemImage: isRegexValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.caption.bold())
                            .foregroundColor(isRegexValid ? .green : .red)
                    }
                    
                    Button("Always open with \(selectedBrowser?.name ?? "")") {
                        cancelAITask()
                        saveAndOpen()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!isRegexValid || testUrl != url.absoluteString)
                }
            }
        }
    }
    
    private func handleOpen() {
        guard let browser = selectedBrowser else { return }
        
        if alwaysOpen {
            selectedPattern = NSRegularExpression.escapedPattern(for: url.host ?? url.absoluteString)
            showPatternSelection = true
            startAITask(for: browser)
        } else {
            Router.shared.open(url: url, with: browser.bundleId)
            Router.shared.isShowingPicker = false
        }
    }
    
    private func startAITask(for browser: InstalledBrowser) {
        cancelAITask()
        isGeneratingPatterns = true
        
        aiTask = Task {
            do {
                let patterns = try await AIClient.shared.suggestRegexes(for: url.absoluteString, browserName: browser.name)
                if !Task.isCancelled {
                    DispatchQueue.main.async {
                        self.suggestedPatterns = patterns
                        self.isGeneratingPatterns = false
                    }
                }
            } catch {
                if !Task.isCancelled {
                    DispatchQueue.main.async {
                        self.isGeneratingPatterns = false
                    }
                }
            }
        }
    }
    
    private func cancelAITask() {
        aiTask?.cancel()
        aiTask = nil
        isGeneratingPatterns = false
    }
    
    private func saveAndOpen() {
        guard let browser = selectedBrowser else { return }
        let rule = BrowserRule(name: browser.name, bundleId: browser.bundleId, pattern: selectedPattern)
        RulesStore.shared.add(rule: rule)
        Router.shared.open(url: url, with: browser.bundleId)
        Router.shared.isShowingPicker = false
    }
}
