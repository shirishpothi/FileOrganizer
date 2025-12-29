//
//  ResponseParser.swift
//  FileOrganizer
//
//  Parses AI JSON responses into OrganizationPlan
//

import Foundation

struct ResponseParser {
    struct AIResponse: Codable {
        let folders: [FolderResponse]
        let unorganized: [UnorganizedFileResponse]?
        let notes: String?
    }
    
    struct FolderResponse: Codable {
        let name: String
        let description: String?
        let reasoning: String?
        let subfolders: [FolderResponse]?
        let files: [String]
    }
    
    struct UnorganizedFileResponse: Codable {
        let filename: String
        let reason: String
    }
    
    static func parseResponse(_ jsonString: String, originalFiles: [FileItem]) throws -> OrganizationPlan {
        // Clean the JSON string - remove markdown code blocks if present
        var cleanedJSON = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanedJSON.hasPrefix("```json") {
            cleanedJSON = String(cleanedJSON.dropFirst(7))
        }
        if cleanedJSON.hasPrefix("```") {
            cleanedJSON = String(cleanedJSON.dropFirst(3))
        }
        if cleanedJSON.hasSuffix("```") {
            cleanedJSON = String(cleanedJSON.dropLast(3))
        }
        cleanedJSON = cleanedJSON.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData = cleanedJSON.data(using: .utf8) else {
            throw ParserError.invalidJSON
        }
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(AIResponse.self, from: jsonData)
        
        // Convert response to OrganizationPlan
        let suggestions = response.folders.map { folder in
            convertFolderResponse(folder, originalFiles: originalFiles)
        }
        
        let unorganizedDetails = (response.unorganized ?? []).map { unorg in
            UnorganizedFile(filename: unorg.filename, reason: unorg.reason)
        }
        
        let unorganizedFiles = unorganizedDetails.compactMap { detail -> FileItem? in
            originalFiles.first { $0.displayName == detail.filename }
        }
        
        return OrganizationPlan(
            suggestions: suggestions,
            unorganizedFiles: unorganizedFiles,
            unorganizedDetails: unorganizedDetails,
            notes: response.notes ?? "",
            timestamp: Date(),
            version: 1
        )
    }
    
    private static func convertFolderResponse(_ folder: FolderResponse, originalFiles: [FileItem]) -> FolderSuggestion {
        let files = folder.files.compactMap { filename -> FileItem? in
            originalFiles.first { $0.displayName == filename || $0.name == filename }
        }
        
        let subfolders = (folder.subfolders ?? []).map { subfolder in
            convertFolderResponse(subfolder, originalFiles: originalFiles)
        }
        
        return FolderSuggestion(
            folderName: folder.name,
            description: folder.description ?? "",
            files: files,
            subfolders: subfolders,
            reasoning: folder.reasoning ?? folder.description ?? ""
        )
    }
    
    static func validateStructure(_ jsonString: String) -> Bool {
        do {
            var cleanedJSON = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleanedJSON.hasPrefix("```json") {
                cleanedJSON = String(cleanedJSON.dropFirst(7))
            }
            if cleanedJSON.hasPrefix("```") {
                cleanedJSON = String(cleanedJSON.dropFirst(3))
            }
            if cleanedJSON.hasSuffix("```") {
                cleanedJSON = String(cleanedJSON.dropLast(3))
            }
            cleanedJSON = cleanedJSON.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard let jsonData = cleanedJSON.data(using: .utf8) else {
                return false
            }
            
            let _ = try JSONDecoder().decode(AIResponse.self, from: jsonData)
            return true
        } catch {
            return false
        }
    }
}

enum ParserError: LocalizedError {
    case invalidJSON
    case missingRequiredFields
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return "Invalid JSON response from AI"
        case .missingRequiredFields:
            return "Response missing required fields"
        case .fileNotFound:
            return "Referenced file not found in original list"
        }
    }
}
