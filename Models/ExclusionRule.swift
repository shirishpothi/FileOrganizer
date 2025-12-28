//
//  ExclusionRule.swift
//  FileOrganizer
//
//  Exclusion rules for file organization
//

import Foundation
import SwiftUI

public enum ExclusionRuleType: String, Codable {
    case fileExtension
    case fileName
    case folderName
    case pathContains
}

public struct ExclusionRule: Codable, Identifiable {
    public let id: UUID
    public var type: ExclusionRuleType
    public var pattern: String
    public var isEnabled: Bool
    public var description: String?
    
    public init(
        id: UUID = UUID(),
        type: ExclusionRuleType,
        pattern: String,
        isEnabled: Bool = true,
        description: String? = nil
    ) {
        self.id = id
        self.type = type
        self.pattern = pattern
        self.isEnabled = isEnabled
        self.description = description
    }
    
    func matches(_ file: FileItem) -> Bool {
        guard isEnabled else { return false }
        
        switch type {
        case .fileExtension:
            return file.extension.lowercased() == pattern.lowercased()
        case .fileName:
            return file.name.localizedCaseInsensitiveContains(pattern)
        case .folderName:
            // Check if file is in a folder matching the pattern
            let pathComponents = file.path.components(separatedBy: "/")
            return pathComponents.contains { $0.localizedCaseInsensitiveContains(pattern) }
        case .pathContains:
            return file.path.localizedCaseInsensitiveContains(pattern)
        }
    }
}

@MainActor
public class ExclusionRulesManager: ObservableObject {
    @Published public private(set) var rules: [ExclusionRule] = []
    private let userDefaults = UserDefaults.standard
    private let rulesKey = "exclusionRules"
    
    public init() {
        loadRules()
        if rules.isEmpty {
            setupDefaultRules()
        }
    }
    
    public func addRule(_ rule: ExclusionRule) {
        rules.append(rule)
        saveRules()
    }
    
    public func removeRule(_ rule: ExclusionRule) {
        rules.removeAll { $0.id == rule.id }
        saveRules()
    }
    
    public func updateRule(_ rule: ExclusionRule) {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index] = rule
            saveRules()
        }
    }
    
    func shouldExclude(_ file: FileItem) -> Bool {
        rules.contains { $0.matches(file) }
    }
    
    func filterFiles(_ files: [FileItem]) -> [FileItem] {
        files.filter { !shouldExclude($0) }
    }
    
    private func setupDefaultRules() {
        let defaultRules = [
            ExclusionRule(type: .folderName, pattern: ".git", description: "Git repositories"),
            ExclusionRule(type: .folderName, pattern: ".svn", description: "SVN repositories"),
            ExclusionRule(type: .folderName, pattern: "node_modules", description: "Node modules"),
            ExclusionRule(type: .fileExtension, pattern: "app", description: "Application bundles")
        ]
        rules = defaultRules
        saveRules()
    }
    
    private func loadRules() {
        if let data = userDefaults.data(forKey: rulesKey),
           let decoded = try? JSONDecoder().decode([ExclusionRule].self, from: data) {
            rules = decoded
        }
    }
    
    private func saveRules() {
        if let encoded = try? JSONEncoder().encode(rules) {
            userDefaults.set(encoded, forKey: rulesKey)
        }
    }
}

