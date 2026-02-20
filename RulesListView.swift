import SwiftUI

struct RulesListView: View {
    @StateObject var store = RulesStore.shared
    @State private var showingSettingsSheet = false
    @State private var testURL: String = ""
    @State private var testResult: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Routing Rules")
                    .font(.title2.bold())
                Spacer()
                
                Button {
                    showingSettingsSheet = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Settings")
            }
            .padding(20)
            .background(Color.secondary.opacity(0.05))
            
            // Test Area
            VStack(alignment: .leading, spacing: 10) {
                Text("Simulate Link Opening")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("Paste a URL to test macOS routing behavior...", text: $testURL)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.1)))
                    
                    Button("Open in System") {
                        performURLTest()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(testURL.isEmpty)
                }
                
                Text("This will hide this window and request macOS to open the link.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
            
            // Rules List
            List {
                if store.rules.isEmpty {
                    emptyStateView
                } else {
                    let grouped = Dictionary(grouping: store.rules, by: { $0.name })
                    let browserNames = grouped.keys.sorted()
                    
                    ForEach(browserNames, id: \.self) { browserName in
                        Section(header: Text(browserName).font(.headline).foregroundColor(.accentColor).padding(.top, 8)) {
                            ForEach(grouped[browserName] ?? []) { rule in
                                RuleRow(rule: rule)
                                    .padding(.vertical, 2)
                                    .listRowSeparator(.hidden)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsView()
                .frame(width: 400, height: 450)
                .padding()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "safari")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No rules created")
                .font(.headline)
            Text("Use the test button above to simulate a link and create your first rule.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .listRowBackground(Color.clear)
    }
    
    private func performURLTest() {
        var urlString = testURL.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !urlString.lowercased().hasPrefix("http://") && !urlString.lowercased().hasPrefix("https://") {
            urlString = "https://" + urlString
        }
        
        guard let _ = URL(string: urlString) else {
            return
        }
        
        NSApp.hide(nil)
        
        let finalURL = urlString
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = [finalURL]
            
            try? process.run()
            self.testURL = ""
        }
    }
}

struct RuleRow: View {
    let rule: BrowserRule
    
    var body: some View {
        HStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 4) {
                Text(rule.pattern)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
            }
            Spacer()
            
            Button(role: .destructive) {
                RulesStore.shared.remove(rule: rule)
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.05)))
    }
}
