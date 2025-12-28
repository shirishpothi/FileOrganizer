//
//  SettingsView.swift
//  FileOrganizer
//
//  API configuration view
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: SettingsViewModel
    @State private var testConnectionStatus: String?
    @State private var isTestingConnection = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("AI Provider") {
                    Picker("Provider", selection: $viewModel.config.provider) {
                        ForEach(Array(AIProvider.allCases), id: \.self) { provider in
                            HStack {
                                Text(provider.displayName)
                                if provider == .appleFoundationModel {
                                    Spacer()
                                    if viewModel.isAppleIntelligenceAvailable {
                                        Label("Available", systemImage: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                    } else {
                                        Label("Unavailable", systemImage: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.caption)
                                    }
                                }
                            }
                            .tag(provider)
                        }
                    }
                    .pickerStyle(.radioGroup)
                }
                
                if viewModel.config.provider == .openAICompatible {
                    Section("API Configuration") {
                        TextField("API URL", text: Binding(
                            get: { viewModel.config.apiURL ?? "" },
                            set: { viewModel.config.apiURL = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        
                        SecureField("API Key", text: Binding(
                            get: { viewModel.config.apiKey ?? "" },
                            set: { viewModel.config.apiKey = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        
                        TextField("Model", text: $viewModel.config.model)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                Section("AI Settings") {
                    VStack(alignment: .leading) {
                        Text("Temperature: \(viewModel.config.temperature, specifier: "%.2f")")
                        Slider(value: $viewModel.config.temperature, in: 0...1, step: 0.1)
                    }
                }
                
                Section {
                    Button(action: testConnection) {
                        HStack {
                            if isTestingConnection {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text("Test Connection")
                        }
                    }
                    .disabled(isTestingConnection || viewModel.config.provider == .appleFoundationModel)
                    
                    if let status = testConnectionStatus {
                        Text(status)
                            .font(.caption)
                            .foregroundColor(status.contains("Success") ? .green : .red)
                    }
                }
                
                Section("Advanced") {
                    NavigationLink("Exclusion Rules") {
                        ExclusionRulesView()
                    }
                }
            }
            .navigationTitle("Settings")
            .formStyle(.grouped)
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

