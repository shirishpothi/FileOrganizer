//
//  OrganizationPlan.swift
//  FileOrganizer
//
//  Complete Organization Proposal
//

import Foundation

public struct OrganizationPlan: Codable, Identifiable {
    public let id: UUID
    public var suggestions: [FolderSuggestion]
    public var unorganizedFiles: [FileItem]
    public var notes: String
    public var timestamp: Date
    public var version: Int
    
    public init(
        id: UUID = UUID(),
        suggestions: [FolderSuggestion] = [],
        unorganizedFiles: [FileItem] = [],
        notes: String = "",
        timestamp: Date = Date(),
        version: Int = 1
    ) {
        self.id = id
        self.suggestions = suggestions
        self.unorganizedFiles = unorganizedFiles
        self.notes = notes
        self.timestamp = timestamp
        self.version = version
    }
    
    public var totalFiles: Int {
        suggestions.reduce(0) { $0 + $1.totalFileCount } + unorganizedFiles.count
    }
    
    public var totalFolders: Int {
        func countFolders(_ folders: [FolderSuggestion]) -> Int {
            folders.count + folders.reduce(0) { $0 + countFolders($1.subfolders) }
        }
        return countFolders(suggestions)
    }
}

