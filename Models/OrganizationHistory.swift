//
//  OrganizationHistory.swift
//  FileOrganizer
//
//  Organization history and analytics
//

import Foundation

public struct OrganizationHistoryEntry: Codable, Identifiable {
    public let id: UUID
    public let timestamp: Date
    public let directoryPath: String
    public let filesOrganized: Int
    public let foldersCreated: Int
    public let plan: OrganizationPlan
    public let success: Bool
    public let errorMessage: String?
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        directoryPath: String,
        filesOrganized: Int,
        foldersCreated: Int,
        plan: OrganizationPlan,
        success: Bool = true,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.directoryPath = directoryPath
        self.filesOrganized = filesOrganized
        self.foldersCreated = foldersCreated
        self.plan = plan
        self.success = success
        self.errorMessage = errorMessage
    }
}

@MainActor
public class OrganizationHistory: ObservableObject {
    @Published public private(set) var entries: [OrganizationHistoryEntry] = []
    private let userDefaults = UserDefaults.standard
    private let historyKey = "organizationHistory"
    private let maxEntries = 100
    
    public init() {
        loadHistory()
    }
    
    public func addEntry(_ entry: OrganizationHistoryEntry) {
        entries.insert(entry, at: 0)
        if entries.count > maxEntries {
            entries.removeLast()
        }
        saveHistory()
    }
    
    public func clearHistory() {
        entries.removeAll()
        saveHistory()
    }
    
    public var totalFilesOrganized: Int {
        entries.reduce(0) { $0 + $1.filesOrganized }
    }
    
    public var totalFoldersCreated: Int {
        entries.reduce(0) { $0 + $1.foldersCreated }
    }
    
    public var successRate: Double {
        guard !entries.isEmpty else { return 0 }
        let successful = entries.filter { $0.success }.count
        return Double(successful) / Double(entries.count)
    }
    
    private func loadHistory() {
        if let data = userDefaults.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([OrganizationHistoryEntry].self, from: data) {
            entries = decoded
        }
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(entries) {
            userDefaults.set(encoded, forKey: historyKey)
        }
    }
}

