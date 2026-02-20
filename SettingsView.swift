import SwiftUI

struct SettingsView: View {
    @StateObject private var configStore = AIConfigStore.shared
    @Environment(\.dismiss) var dismiss
    @State private var models: [String] = []
    @State private var isLoadingModels = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Settings")
                    .font(.title2.bold())
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // System Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("System Integration", systemImage: "cpu")
                            .font(.headline)
                        
                        Text("To work correctly, you must set this app as your default browser in macOS System Settings.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button("Open System Settings") {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.general") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Divider()
                    
                    // AI Section
                    VStack(alignment: .leading, spacing: 16) {
                        Label("AI Configuration", systemImage: "sparkles")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Base URL")
                                .font(.caption.bold())
                            TextField("http://localhost:11434", text: $configStore.config.baseURL)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("API Key (Optional)")
                                .font(.caption.bold())
                            SecureField("Leave empty for local providers", text: Binding(
                                get: { configStore.config.apiKey ?? "" },
                                set: { configStore.config.apiKey = $0.isEmpty ? nil : $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Model")
                                    .font(.caption.bold())
                                Spacer()
                                if isLoadingModels {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Button(action: refreshModels) {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            
                            if !models.isEmpty {
                                Picker("Select a model", selection: $configStore.config.model) {
                                    ForEach(models, id: \.self) { model in
                                        Text(model).tag(model)
                                    }
                                }
                                .pickerStyle(.menu)
                            } else {
                                TextField("e.g., llama3", text: $configStore.config.model)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                        
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .padding()
        .onAppear {
            refreshModels()
        }
    }
    
    private func refreshModels() {
        isLoadingModels = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedModels = try await AIClient.shared.fetchModels(
                    baseURL: configStore.config.baseURL,
                    apiKey: configStore.config.apiKey
                )
                DispatchQueue.main.async {
                    self.models = fetchedModels
                    if let first = fetchedModels.first, configStore.config.model.isEmpty {
                        configStore.config.model = first
                    }
                    self.isLoadingModels = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to fetch models. Check your Base URL."
                    self.isLoadingModels = false
                }
            }
        }
    }
}
