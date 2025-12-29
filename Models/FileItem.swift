//
//  FileItem.swift
//  FileOrganizer
//
//  File and Directory Model
//

import Foundation

public struct FileItem: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var path: String
    public var name: String
    public var `extension`: String
    public var size: Int64
    public var isDirectory: Bool
    public var creationDate: Date?
    
    // Deep scanning metadata
    public var contentMetadata: ContentMetadata?
    
    // For duplicate detection (SHA-256)
    public var sha256Hash: String?
    
    public init(
        id: UUID = UUID(),
        path: String,
        name: String,
        extension: String = "",
        size: Int64 = 0,
        isDirectory: Bool = false,
        creationDate: Date? = nil,
        contentMetadata: ContentMetadata? = nil,
        sha256Hash: String? = nil
    ) {
        self.id = id
        self.path = path
        self.name = name
        self.extension = `extension`
        self.size = size
        self.isDirectory = isDirectory
        self.creationDate = creationDate
        self.contentMetadata = contentMetadata
        self.sha256Hash = sha256Hash
    }
    
    public var url: URL? {
        URL(fileURLWithPath: path)
    }
    
    public var displayName: String {
        if `extension`.isEmpty {
            return name
        }
        return "\(name).\(`extension`)"
    }
    
    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

