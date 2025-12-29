//
//  FileSystemManager.swift
//  FileOrganizer
//
//  Safe file operations with undo tracking and conflict handling
//

import Foundation

public actor FileSystemManager {
    private var undoStack: [FileOperation] = []
    private let fileManager = FileManager.default
    
    public struct FileOperation: Codable, Hashable, Sendable {
        let id: UUID
        let type: OperationType
        let sourcePath: String
        let destinationPath: String?
        let timestamp: Date
        
        enum OperationType: String, Codable {
            case createFolder
            case moveFile
        }
    }
    
    func createFolders(_ plan: OrganizationPlan, at baseURL: URL, dryRun: Bool = false) async throws -> [FileOperation] {
        var operations: [FileOperation] = []
        
        func createFolderRecursive(_ suggestion: FolderSuggestion, parentURL: URL) throws {
            let folderURL = parentURL.appendingPathComponent(suggestion.folderName, isDirectory: true)
            
            if !dryRun {
                var isDirectory: ObjCBool = false
                if fileManager.fileExists(atPath: folderURL.path, isDirectory: &isDirectory) {
                    if isDirectory.boolValue {
                        // Idempotent: Folder exists, continue with subfolders
                    } else {
                        // Conflict: File exists where folder should be. Rename existing file.
                        let backupURL = folderURL.deletingLastPathComponent()
                            .appendingPathComponent("\(suggestion.folderName)_file_backup_\(UUID().uuidString.prefix(8))")
                        try fileManager.moveItem(at: folderURL, to: backupURL)
                        try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
                        
                        operations.append(FileOperation(
                            id: UUID(),
                            type: .createFolder,
                            sourcePath: folderURL.path,
                            destinationPath: nil,
                            timestamp: Date()
                        ))
                    }
                } else {
                    try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
                    operations.append(FileOperation(
                        id: UUID(),
                        type: .createFolder,
                        sourcePath: folderURL.path,
                        destinationPath: nil,
                        timestamp: Date()
                    ))
                }
            }
            
            // Create subfolders
            for subfolder in suggestion.subfolders {
                try createFolderRecursive(subfolder, parentURL: folderURL)
            }
        }
        
        for suggestion in plan.suggestions {
            try createFolderRecursive(suggestion, parentURL: baseURL)
        }
        
        return operations
    }
    
    func moveFiles(_ plan: OrganizationPlan, at baseURL: URL, dryRun: Bool = false) async throws -> [FileOperation] {
        var operations: [FileOperation] = []
        
        func moveFilesInSuggestion(_ suggestion: FolderSuggestion, parentURL: URL) throws {
            let folderURL = parentURL.appendingPathComponent(suggestion.folderName, isDirectory: true)
            
            // Move files in this folder
            for file in suggestion.files {
                guard let sourceURL = file.url else { continue }
                var destinationURL = folderURL.appendingPathComponent(sourceURL.lastPathComponent)
                
                // CRITICAL: Handle re-organization of already organized folders
                // If the source and destination are already identical, skip it
                if sourceURL.standardizedFileURL.path == destinationURL.standardizedFileURL.path {
                    continue
                }
                
                if !dryRun {
                    // Create destination directory if it doesn't exist
                    if !fileManager.fileExists(atPath: folderURL.path) {
                        try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
                    }
                    
                    // Handle file conflicts - generate unique name if destination exists
                    if fileManager.fileExists(atPath: destinationURL.path) {
                        destinationURL = generateUniqueURL(for: destinationURL)
                    }
                    
                    // Check if source still exists
                    guard fileManager.fileExists(atPath: sourceURL.path) else {
                        continue
                    }
                    
                    // Move file
                    try fileManager.moveItem(at: sourceURL, to: destinationURL)
                }
                
                operations.append(FileOperation(
                    id: UUID(),
                    type: .moveFile,
                    sourcePath: sourceURL.path,
                    destinationPath: destinationURL.path,
                    timestamp: Date()
                ))
            }
            
            // Recursively move files in subfolders
            for subfolder in suggestion.subfolders {
                try moveFilesInSuggestion(subfolder, parentURL: folderURL)
            }
        }
        
        for suggestion in plan.suggestions {
            try moveFilesInSuggestion(suggestion, parentURL: baseURL)
        }
        
        return operations
    }
    
    /// Generate a unique filename by appending a counter
    private func generateUniqueURL(for url: URL) -> URL {
        let directory = url.deletingLastPathComponent()
        let filename = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        
        var counter = 1
        var newURL = url
        
        while fileManager.fileExists(atPath: newURL.path) {
            let newName = ext.isEmpty ? "\(filename)_\(counter)" : "\(filename)_\(counter).\(ext)"
            newURL = directory.appendingPathComponent(newName)
            counter += 1
        }
        
        return newURL
    }
    
    func applyOrganization(_ plan: OrganizationPlan, at baseURL: URL, dryRun: Bool = false) async throws -> [FileOperation] {
        var allOperations: [FileOperation] = []
        
        // First create all folders
        let folderOps = try await createFolders(plan, at: baseURL, dryRun: dryRun)
        allOperations.append(contentsOf: folderOps)
        
        // Then move all files
        let fileOps = try await moveFiles(plan, at: baseURL, dryRun: dryRun)
        allOperations.append(contentsOf: fileOps)
        
        if !dryRun {
            undoStack.append(contentsOf: allOperations)
        }
        
        return allOperations
    }
    
    /// Reverses a set of operations (undo/rollback)
    func reverseOperations(_ operations: [FileOperation]) async throws {
        // Reverse in opposite order of creation
        for operation in operations.reversed() {
            switch operation.type {
            case .createFolder:
                // Only remove if empty
                if fileManager.fileExists(atPath: operation.sourcePath) {
                    let contents = try? fileManager.contentsOfDirectory(atPath: operation.sourcePath)
                    if contents?.isEmpty == true {
                        try fileManager.removeItem(atPath: operation.sourcePath)
                    }
                }
            case .moveFile:
                if let destinationPath = operation.destinationPath,
                   fileManager.fileExists(atPath: destinationPath) {
                    // Ensure the original directory exists
                    let originalDir = URL(fileURLWithPath: operation.sourcePath).deletingLastPathComponent()
                    if !fileManager.fileExists(atPath: originalDir.path) {
                        try fileManager.createDirectory(at: originalDir, withIntermediateDirectories: true)
                    }
                    
                    // Check if original location is occupied
                    var finalSourcePath = operation.sourcePath
                    if fileManager.fileExists(atPath: finalSourcePath) {
                        let uniqueURL = generateUniqueURL(for: URL(fileURLWithPath: finalSourcePath))
                        finalSourcePath = uniqueURL.path
                    }
                    
                    try fileManager.moveItem(atPath: destinationPath, toPath: finalSourcePath)
                }
            }
        }
    }
    
    func undoLastOperation() async throws {
        guard let lastOperation = undoStack.last else {
            throw FileSystemError.noOperationToUndo
        }
        
        // This is a simplified undo. For multi-state, we use reverseOperations.
        try await reverseOperations([lastOperation])
        undoStack.removeLast()
    }
    
    func clearUndoStack() {
        undoStack.removeAll()
    }
}

enum FileSystemError: LocalizedError {
    case noOperationToUndo
    case fileNotFound
    case permissionDenied
    case invalidPath
    case pathAlreadyExists(String)
    
    var errorDescription: String? {
        switch self {
        case .noOperationToUndo:
            return "No operation to undo"
        case .fileNotFound:
            return "File not found"
        case .permissionDenied:
            return "Permission denied"
        case .invalidPath:
            return "Invalid path"
        case .pathAlreadyExists(let path):
            return "Path already exists: \(path). The file was skipped or renamed."
        }
    }
}
