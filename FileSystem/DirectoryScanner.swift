//
//  DirectoryScanner.swift
//  FileOrganizer
//
//  Recursively scans directories and builds file tree
//

import Foundation

actor DirectoryScanner {
    private var isScanning = false
    private var scannedCount = 0
    
    func scanDirectory(at url: URL, includeHidden: Bool = false) async throws -> [FileItem] {
        guard !isScanning else {
            throw ScannerError.alreadyScanning
        }
        
        isScanning = true
        scannedCount = 0
        defer { isScanning = false }
        
        var files: [FileItem] = []
        let fileManager = FileManager.default
        
        guard url.isFileURL else {
            throw ScannerError.invalidURL
        }
        
        guard fileManager.fileExists(atPath: url.path) else {
            throw ScannerError.pathNotFound
        }
        
        try await scanDirectoryRecursive(
            at: url,
            fileManager: fileManager,
            includeHidden: includeHidden,
            files: &files
        )
        
        return files
    }
    
    private func scanDirectoryRecursive(
        at url: URL,
        fileManager: FileManager,
        includeHidden: Bool,
        files: inout [FileItem]
    ) async throws {
        let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .fileSizeKey, .creationDateKey, .isHiddenKey]
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsPackageDescendants, .skipsHiddenFiles]
        ) else {
            throw ScannerError.enumerationFailed
        }
        
        while let fileURL = enumerator.nextObject() as? URL {
            // Skip hidden files if not including them
            if !includeHidden {
                let resourceValues = try? fileURL.resourceValues(forKeys: [.isHiddenKey])
                if resourceValues?.isHidden == true {
                    continue
                }
            }
            
            // Get file attributes
            let resourceValues = try? fileURL.resourceValues(forKeys: Set(resourceKeys))
            let isDirectory = resourceValues?.isDirectory ?? false
            let size = resourceValues?.fileSize ?? 0
            let creationDate = resourceValues?.creationDate
            
            // Skip if it's a directory (we only want files)
            if isDirectory {
                continue
            }
            
            let pathExtension = fileURL.pathExtension
            let fileName = fileURL.deletingPathExtension().lastPathComponent
            
            let fileItem = FileItem(
                path: fileURL.path,
                name: fileName,
                extension: pathExtension,
                size: Int64(size),
                isDirectory: false,
                creationDate: creationDate
            )
            
            files.append(fileItem)
            scannedCount += 1
            
            // Yield to allow UI updates
            if scannedCount % 100 == 0 {
                await Task.yield()
            }
        }
    }
    
    func getProgress() -> Int {
        scannedCount
    }
}

enum ScannerError: LocalizedError {
    case alreadyScanning
    case invalidURL
    case pathNotFound
    case enumerationFailed
    
    var errorDescription: String? {
        switch self {
        case .alreadyScanning:
            return "A scan is already in progress"
        case .invalidURL:
            return "Invalid URL provided"
        case .pathNotFound:
            return "The specified path does not exist"
        case .enumerationFailed:
            return "Failed to enumerate directory contents"
        }
    }
}

