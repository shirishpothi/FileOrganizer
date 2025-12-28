//
//  FolderOrganizer.swift
//  FileOrganizer
//
//  Main orchestrator for organization workflow
//

import Foundation
import SwiftUI

public enum OrganizationState: Equatable {
    case idle
    case scanning
    case analyzing
    case ready
    case applying
    case completed
    case error(Error)
    
    public static func == (lhs: OrganizationState, rhs: OrganizationState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.scanning, .scanning),
             (.analyzing, .analyzing),
             (.ready, .ready),
             (.applying, .applying),
             (.completed, .completed):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

@MainActor
public class FolderOrganizer: ObservableObject {
    @Published public var state: OrganizationState = .idle
    @Published public var progress: Double = 0.0
    @Published public var currentPlan: OrganizationPlan?
    @Published public var errorMessage: String?
    
    var scanner = DirectoryScanner()
    var aiClient: AIClientProtocol?
    private let fileSystemManager = FileSystemManager()
    private let validator = FileOrganizationValidator.self
    public let history = OrganizationHistory()
    public var exclusionRules: ExclusionRulesManager?
    
    public init() {}
    
    public func configure(with config: AIConfig) throws {
        aiClient = try AIClientFactory.createClient(config: config)
    }
    
    public func organize(directory: URL) async throws {
        guard let client = aiClient else {
            throw OrganizationError.clientNotConfigured
        }
        
        state = .scanning
        progress = 0.1
        
        // Scan directory
        var files = try await scanner.scanDirectory(at: directory)
        progress = 0.3
        
        // Apply exclusion rules
        if let exclusionRules = exclusionRules {
            // #region agent log
            DebugLogger.log(hypothesisId: "E", location: "FolderOrganizer.swift:51", message: "Accessing exclusionRules from @MainActor", data: [
                "filesBefore": files.count,
                "exclusionRulesExists": true
            ])
            // #endregion
            files = exclusionRules.filterFiles(files)
            // #region agent log
            DebugLogger.log(hypothesisId: "E", location: "FolderOrganizer.swift:53", message: "After exclusion rules filter", data: [
                "filesAfter": files.count
            ])
            // #endregion
        }
        
        state = .analyzing
        progress = 0.5
        
        // Analyze with AI
        let plan = try await client.analyze(files: files)
        progress = 0.8
        
        // Validate plan
        try validator.validate(plan, at: directory)
        progress = 1.0
        
        currentPlan = plan
        state = .ready
    }
    
    public func regeneratePreview() async throws {
        guard let client = aiClient else {
            throw OrganizationError.clientNotConfigured
        }
        
        guard let currentPlan = currentPlan else {
            throw OrganizationError.noCurrentPlan
        }
        
        // Get original files from current plan
        var allFiles: [FileItem] = []
        func collectFiles(_ suggestion: FolderSuggestion) {
            allFiles.append(contentsOf: suggestion.files)
            for subfolder in suggestion.subfolders {
                collectFiles(subfolder)
            }
        }
        for suggestion in currentPlan.suggestions {
            collectFiles(suggestion)
        }
        allFiles.append(contentsOf: currentPlan.unorganizedFiles)
        
        state = .analyzing
        progress = 0.5
        
        // Generate new plan
        var newPlan = try await client.analyze(files: allFiles)
        newPlan.version = (currentPlan.version) + 1
        
        progress = 1.0
        self.currentPlan = newPlan
        state = .ready
    }
    
    public func apply(at baseURL: URL, dryRun: Bool = false) async throws {
        guard let plan = currentPlan else {
            throw OrganizationError.noCurrentPlan
        }
        
        state = .applying
        progress = 0.0
        
        _ = try await fileSystemManager.applyOrganization(plan, at: baseURL, dryRun: dryRun)
        
        // Add to history
        let historyEntry = OrganizationHistoryEntry(
            directoryPath: baseURL.path,
            filesOrganized: plan.totalFiles,
            foldersCreated: plan.totalFolders,
            plan: plan,
            success: true
        )
        history.addEntry(historyEntry)
        
        progress = 1.0
        state = .completed
    }
    
    public func reset() {
        state = .idle
        progress = 0.0
        currentPlan = nil
        errorMessage = nil
    }
}

enum OrganizationError: LocalizedError {
    case clientNotConfigured
    case noCurrentPlan
    case invalidDirectory
    
    var errorDescription: String? {
        switch self {
        case .clientNotConfigured:
            return "AI client not configured"
        case .noCurrentPlan:
            return "No organization plan available"
        case .invalidDirectory:
            return "Invalid directory"
        }
    }
}

