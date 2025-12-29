//
//  SettingsView.swift
//  FileOrganizer
//
//  API configuration view with advanced settings
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: SettingsViewModel
    @EnvironmentObject var personaManager: PersonaManager // Access persona manager
    @State private var testConnectionStatus: String?
    @State private var isTestingConnection = false
    @State private var showingAdvanced = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Main content
                    Form {
                        // AI Provider Section
                        Section {
                            Picker("Provider", selection: $viewModel.config.provider) {
                                ForEach(Array(AIProvider.allCases), id: \.self) { provider in
                                    HStack {
                                        Text(provider.displayName)
                                        Spacer()
                                        if !provider.isAvailable {
                                            Label("Unavailable", systemImage: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                                .font(.caption)
                                        }
                                    }
                                    .tag(provider)
                                }
                            }
                            .pickerStyle(.radioGroup)
                            .accessibilityLabel("AI Provider Selection")
                            
                            if !viewModel.config.provider.isAvailable,
                               let reason = viewModel.config.provider.unavailabilityReason {
                                Label(reason, systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .padding(.vertical, 4)
                            }
                        } header: {
                            Text("AI Provider")
                        }
                        
                        // API Configuration (for OpenAI)
                        if viewModel.config.provider == .openAICompatible {
                            Section {
                                TextField("API URL", text: Binding(
                                    get: { viewModel.config.apiURL ?? "" },
                                    set: { viewModel.config.apiURL = $0.isEmpty ? nil : $0 }
                                ))
                                .textFieldStyle(.roundedBorder)
                                .accessibilityLabel("API URL")
                                
                                HStack {
                                    SecureField("API Key", text: Binding(
                                        get: { viewModel.config.apiKey ?? "" },
                                        set: { viewModel.config.apiKey = $0.isEmpty ? nil : $0 }
                                    ))
                                    .textFieldStyle(.roundedBorder)
                                    .accessibilityLabel("API Key")
                                    
                                    if !viewModel.config.requiresAPIKey {
                                        Text("Optional")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                TextField("Model", text: $viewModel.config.model)
                                    .textFieldStyle(.roundedBorder)
                                    .accessibilityLabel("Model Name")
                            } header: {
                                Text("API Configuration")
                            }
                        }
                        
                        // Organization Strategy
                        Section {
                            Toggle(isOn: $viewModel.config.enableReasoning) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Include Reasoning")
                                    Text("AI will explain its organization choices. This will take significantly more time and tokens.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                            
                            Toggle(isOn: $viewModel.config.enableDeepScan) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Deep Scanning")
                                    Text("Analyze file content (PDF text, EXIF data for photos, etc.) for smarter organization.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                            
                            Toggle(isOn: $viewModel.config.detectDuplicates) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Detect Duplicates")
                                    Text("Find files with identical content using SHA-256 hashing. May slow down large scans.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        } header: {
                            Text("Organization Strategy")
                        }
                        
                        // AI Settings
                        Section {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Temperature")
                                    Spacer()
                                    Text("\(viewModel.config.temperature, specifier: "%.2f")")
                                        .foregroundColor(.secondary)
                                        .monospacedDigit()
                                }
                                Slider(value: $viewModel.config.temperature, in: 0...1, step: 0.1)
                                    .accessibilityLabel("Temperature")
                                Text("Lower values = more focused, higher = more creative")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } header: {
                            Text("Parameter Tuning")
                        }
                        
                        // Test Connection
                        Section {
                            HStack(spacing: 12) {
                                Button(action: testConnection) {
                                    HStack {
                                        if isTestingConnection {
                                            ProgressView()
                                                .scaleEffect(0.7)
                                        }
                                        Text("Test Connection")
                                    }
                                }
                                .disabled(isTestingConnection || !viewModel.config.provider.isAvailable)
                                
                                if let status = testConnectionStatus {
                                    Label(
                                        status.contains("Success") ? "Connected" : "Failed",
                                        systemImage: status.contains("Success") ? "checkmark.circle.fill" : "xmark.circle.fill"
                                    )
                                    .foregroundColor(status.contains("Success") ? .green : .red)
                                    .font(.caption)
                                }
                            }
                            
                            if let status = testConnectionStatus, !status.contains("Success") {
                                Text(status)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Advanced Settings (Collapsible)
                        Section {
                            DisclosureGroup("Advanced Settings", isExpanded: $showingAdvanced) {
                                VStack(alignment: .leading, spacing: 16) {
                                    Divider()
                                    
                                    // Persona Picker (Moved here)
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Default Organization Persona")
                                            .font(.headline)
                                        CompactPersonaPicker()
                                    }
                                    .padding(.vertical, 4)
                                    
                                    Divider()
                                    
                                    // Streaming toggle
                                    Toggle("Enable Streaming", isOn: $viewModel.config.enableStreaming)
                                        .accessibilityLabel("Enable response streaming")
                                    
                                    // API Key Required toggle
                                    Toggle("Requires API Key", isOn: $viewModel.config.requiresAPIKey)
                                        .accessibilityLabel("API Key requirement")
                                    Text("Disable for local endpoints that don't require authentication")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Divider()
                                    
                                    // Timeout settings parameters... (Keeping existing logic)
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("Request Timeout")
                                            Spacer()
                                            Text("\(Int(viewModel.config.requestTimeout))s")
                                                .foregroundColor(.secondary)
                                                .monospacedDigit()
                                        }
                                        Slider(value: $viewModel.config.requestTimeout, in: 30...300, step: 10)
                                        Text("Time to wait for initial response")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("Resource Timeout")
                                            Spacer()
                                            Text("\(Int(viewModel.config.resourceTimeout))s")
                                                .foregroundColor(.secondary)
                                                .monospacedDigit()
                                        }
                                        Slider(value: $viewModel.config.resourceTimeout, in: 60...1200, step: 60)
                                        Text("Maximum total request duration")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Divider()
                                    
                                    // Max tokens
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("Max Tokens")
                                            Spacer()
                                            TextField("Auto", value: $viewModel.config.maxTokens, format: .number)
                                                .textFieldStyle(.roundedBorder)
                                                .frame(width: 100)
                                        }
                                        Text("Leave empty for model default")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Divider()
                                    
                                    // System prompt override (Per Persona)
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("Custom System Prompt")
                                            Spacer()
                                            
                                            if let _ = personaManager.customPrompts[personaManager.selectedPersona] {
                                                Button("Reset to Default") {
                                                    personaManager.resetCustomPrompt(for: personaManager.selectedPersona)
                                                }
                                                .font(.caption)
                                                .buttonStyle(.borderless)
                                                .foregroundColor(.red)
                                            }
                                        }
                                        
                                        Text(" customizing for: \(personaManager.selectedPersona.displayName)")
                                            .font(.caption)
                                            .foregroundColor(.purple)
                                        
                                        TextEditor(text: Binding(
                                            get: { personaManager.getPrompt(for: personaManager.selectedPersona) },
                                            set: { newValue in
                                                personaManager.saveCustomPrompt(for: personaManager.selectedPersona, prompt: newValue)
                                            }
                                        ))
                                        .font(.system(.body, design: .monospaced))
                                        .frame(height: 150)
                                        .border(Color.secondary.opacity(0.3), width: 1)
                                        
                                        Text("Customize how the AI behaves for the selected persona.")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }
                        
                        // Watched Folders (Smart Automations)
                        Section {
                            NavigationLink {
                                WatchedFoldersView()
                            } label: {
                                HStack {
                                    Label("Watched Folders", systemImage: "eye")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                            
                            Text("Automatically organize folders like Downloads when new files arrive")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } header: {
                            Text("Smart Automations")
                        }
                        
                        // Exclusion Rules
                        Section {
                            NavigationLink {
                                ExclusionRulesView()
                            } label: {
                                HStack {
                                    Label("Exclusion Rules", systemImage: "eye.slash")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .formStyle(.grouped)
                }
                .padding()
            }
            .navigationTitle("Settings")
        }
    }
    
    private func testConnection() {
        isTestingConnection = true
        testConnectionStatus = nil
        
        Task {
            do {
                try await viewModel.testConnection()
                testConnectionStatus = "Success: Connection test passed"
            } catch {
                testConnectionStatus = "Error: \(error.localizedDescription)"
            }
            isTestingConnection = false
        }
    }
}
