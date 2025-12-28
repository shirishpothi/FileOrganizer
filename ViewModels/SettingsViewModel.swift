//
//  SettingsViewModel.swift
//  FileOrganizer
//
//  Manages API configuration and settings
//

import Foundation
import Combine

@MainActor
public class SettingsViewModel: ObservableObject {
    @Published public var config: AIConfig = .default {
        didSet {
            saveConfig()
        }
    }
    
    @Published public var isAppleIntelligenceAvailable: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let configKey = "aiConfig"
    
    public init() {
        loadConfig()
        checkAppleIntelligenceAvailability()
    }
    
    private func loadConfig() {
        if let data = userDefaults.data(forKey: configKey),
           var decoded = try? JSONDecoder().decode(AIConfig.self, from: data) {
            // Migrate API key from UserDefaults to Keychain if it exists in UserDefaults
            if let oldApiKey = decoded.apiKey, !oldApiKey.isEmpty {
                // Check if already in Keychain
                if KeychainManager.get(key: "apiKey") == nil {
                    // Migrate to Keychain
                    _ = KeychainManager.save(key: "apiKey", value: oldApiKey)
                }
            }
            
            // Load API key from Keychain (preferred source)
            if let apiKey = KeychainManager.get(key: "apiKey") {
                decoded.apiKey = apiKey
            } else {
            }
            config = decoded
        }
    }
    
    private func saveConfig() {
        // #region agent log
        DebugLogger.log(hypothesisId: "B", location: "SettingsViewModel.swift:36", message: "saveConfig called - API key being saved to Keychain", data: [
            "hasAPIKey": config.apiKey != nil,
            "apiKeyLength": config.apiKey?.count ?? 0,
            "provider": config.provider.rawValue
        ])
        // #endregion
        
        // Save API key to Keychain securely
        if let apiKey = config.apiKey {
            _ = KeychainManager.save(key: "apiKey", value: apiKey)
        } else {
            _ = KeychainManager.delete(key: "apiKey")
        }
        
        // Save config without API key to UserDefaults
        var configToSave = config
        configToSave.apiKey = nil // Don't store in UserDefaults
        if let encoded = try? JSONEncoder().encode(configToSave) {
            userDefaults.set(encoded, forKey: configKey)
        }
    }
    
    private func checkAppleIntelligenceAvailability() {
        if #available(macOS 15.0, *) {
            isAppleIntelligenceAvailable = AppleFoundationModelClient.isAvailable()
        } else {
            isAppleIntelligenceAvailable = false
        }
    }
    
    public func testConnection() async throws {
        let client = try AIClientFactory.createClient(config: config)
        // Test with a minimal file list
        let testFiles = [
            FileItem(path: "/test/file1.txt", name: "file1", extension: "txt"),
            FileItem(path: "/test/file2.pdf", name: "file2", extension: "pdf")
        ]
        _ = try await client.analyze(files: testFiles)
    }
}

