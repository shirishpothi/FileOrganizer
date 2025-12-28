//
//  FileSystemManager.swift
//  FileOrganizer
//
//  Safe file operations with undo tracking
//

import Foundation

actor FileSystemManager {
    private var undoStack: [FileOperation] = []
    private let fileManager = FileManager.default
    
    struct FileOperation: Codable {
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
                try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
            }
            
            let operation = FileOperation(
                id: UUID(),
                type: .createFolder,
                sourcePath: folderURL.path,
                destinationPath: nil,
                timestamp: Date()
            )
            operations.append(operation)
            
            // Create subfolders
            for subfolder in suggestion.subfolders {
                try createFolderRecursive(subfolder, parentURL: folderURL)
            }
        }
        
        for suggestion in plan.suggestions {
            try createFolderRecursive(suggestion, parentURL: baseURL)
        }
        
        if !dryRun {
            undoStack.append(contentsOf: operations)
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
                let destinationURL = folderURL.appendingPathComponent(sourceURL.lastPathComponent)
                
                if !dryRun {
                    // Create destination directory if it doesn't exist
                    try? fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
                    
                    // Move file
                    try fileManager.moveItem(at: sourceURL, to: destinationURL)
                }
                
                let operation = FileOperation(
                    id: UUID(),
                    type: .moveFile,
                    sourcePath: sourceURL.path,
                    destinationPath: destinationURL.path,
                    timestamp: Date()
                )
                operations.append(operation)
            }
            
            // Recursively move files in subfolders
            for subfolder in suggestion.subfolders {
                try moveFilesInSuggestion(subfolder, parentURL: folderURL)
            }
        }
        
        for suggestion in plan.suggestions {
            try moveFilesInSuggestion(suggestion, parentURL: baseURL)
        }
        
        if !dryRun {
            undoStack.append(contentsOf: operations)
        }
        
        return operations
    }
    
    func applyOrganization(_ plan: OrganizationPlan, at baseURL: URL, dryRun: Bool = false) async throws -> [FileOperation] {
        var allOperations: [FileOperation] = []
        
        // First create all folders
        let folderOps = try await createFolders(plan, at: baseURL, dryRun: dryRun)
        allOperations.append(contentsOf: folderOps)
        
        // Then move all files
        let fileOps = try await moveFiles(plan, at: baseURL, dryRun: dryRun)
        allOperations.append(contentsOf: fileOps)
        
        return allOperations
    }
    
    func undoLastOperation() async throws {
        guard let lastOperation = undoStack.last else {
            throw FileSystemError.noOperationToUndo
        }
        
        try undoOperation(lastOperation)
        undoStack.removeLast()
    }
    
    func undoOperation(_ operation: FileOperation) throws {
        switch operation.type {
        case .createFolder:
            // Remove created folder
            if fileManager.fileExists(atPath: operation.sourcePath) {
                try fileManager.removeItem(atPath: operation.sourcePath)
            }
            
        case .moveFile:
            // Move file back to original location
            if let destinationPath = operation.destinationPath,
               fileManager.fileExists(atPath: destinationPath) {
                try fileManager.moveItem(atPath: destinationPath, toPath: operation.sourcePath)
            }
        }
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
        }
    }
}

