//
//  PromptBuilder.swift
//  FileOrganizer
//
//  Constructs optimized prompts for AI analysis
//

import Foundation

struct PromptBuilder {
    static func buildSystemPrompt() -> String {
        SystemPrompt.prompt
    }
    
    static func buildAnalysisPrompt(files: [FileItem]) -> String {
        var prompt = "Analyze the following files and suggest an organization structure:\n\n"
        prompt += "Files to organize (\(files.count) total):\n\n"
        
        // Group files by extension for better context
        let groupedByExtension = Dictionary(grouping: files) { $0.extension.lowercased() }
        
        for (ext, fileList) in groupedByExtension.sorted(by: { $0.key < $1.key }) {
            let extLabel = ext.isEmpty ? "no extension" : ".\(ext)"
            prompt += "\(extLabel.uppercased()) files (\(fileList.count)):\n"
            for file in fileList.prefix(50) { // Limit to first 50 per type
                prompt += "  - \(file.displayName) (\(file.formattedSize))\n"
            }
            if fileList.count > 50 {
                prompt += "  ... and \(fileList.count - 50) more \(extLabel) files\n"
            }
        }
        
        prompt += "\nPlease provide the organization structure in the specified JSON format."
        
        return prompt
    }
    
    static func buildPromptForProvider(_ provider: AIProvider, files: [FileItem]) -> String {
        // Provider-specific adaptations can be added here
        return buildAnalysisPrompt(files: files)
    }
}

