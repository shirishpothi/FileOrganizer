//
//  FolderSuggestion.swift
//  FileOrganizer
//
//  AI-Generated Folder Organization Suggestion
//

import Foundation

public struct FolderSuggestion: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public var folderName: String
    public var description: String
    public var files: [FileItem]
    public var subfolders: [FolderSuggestion]
    public var reasoning: String
    
    public init(
        id: UUID = UUID(),
        folderName: String,
        description: String = "",
        files: [FileItem] = [],
        subfolders: [FolderSuggestion] = [],
        reasoning: String = ""
    ) {
        self.id = id
        self.folderName = folderName
        self.description = description
        self.files = files
        self.subfolders = subfolders
        self.reasoning = reasoning
    }
    
    public var totalFileCount: Int {
        files.count + subfolders.reduce(0) { $0 + $1.totalFileCount }
    }
}

