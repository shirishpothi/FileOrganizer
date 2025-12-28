//
//  PreviewView.swift
//  FileOrganizer
//
//  Enhanced preview interface with redo/cancel
//

import SwiftUI

struct PreviewView: View {
    let plan: OrganizationPlan
    let baseURL: URL
    @EnvironmentObject var organizer: FolderOrganizer
    @StateObject private var previewManager = PreviewManager()
    @State private var showApplyConfirmation = false
    @State private var isApplying = false
    
    // Reset isApplying when organizer state changes to completed
    // This ensures UI state is correct even if view doesn't immediately switch
    private var shouldDisableButtons: Bool {
        isApplying || (organizer.state == .applying)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with version info
            HStack {
                Text("Preview \(plan.version)")
                    .font(.headline)
                Spacer()
                Text("\(plan.totalFiles) files • \(plan.totalFolders) folders")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            // Tree view
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(plan.suggestions) { suggestion in
                        FolderTreeView(suggestion: suggestion, level: 0)
                    }
                    
                    if !plan.unorganizedFiles.isEmpty {
                        Section("Unorganized Files") {
                            ForEach(plan.unorganizedFiles) { file in
                                HStack {
                                    Image(systemName: "doc")
                                    Text(file.displayName)
                                    Spacer()
                                    Text(file.formattedSize)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.leading, 20)
                            }
                        }
                        .padding(.top)
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Action buttons
            HStack {
                Button("Cancel") {
                    organizer.reset()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Try Different Organization") {
                    regeneratePreview()
                }
                .disabled(shouldDisableButtons)
                
                Button("Apply Organization") {
                    showApplyConfirmation = true
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(shouldDisableButtons)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Apply Organization?", isPresented: $showApplyConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Apply") {
                applyOrganization()
            }
        } message: {
            Text("This will create \(plan.totalFolders) folders and move \(plan.totalFiles) files. This action can be undone.")
        }
        .onChange(of: organizer.state) { newState in
            // Reset isApplying when organization completes or errors
            if case .completed = newState {
                isApplying = false
            } else if case .error = newState {
                isApplying = false
            }
        }
    }
    
    private func regeneratePreview() {
        Task {
            do {
                try await organizer.regeneratePreview()
            } catch {
                organizer.state = .error(error)
            }
        }
    }
    
    private func applyOrganization() {
        // #region agent log
        DebugLogger.log(hypothesisId: "D", location: "PreviewView.swift:104", message: "applyOrganization called", data: [
            "isApplying": isApplying,
            "baseURL": baseURL.path
        ])
        // #endregion
        isApplying = true
        Task { @MainActor in
            do {
                try await organizer.apply(at: baseURL, dryRun: false)
                // #region agent log
                DebugLogger.log(hypothesisId: "D", location: "PreviewView.swift:109", message: "applyOrganization succeeded", data: [
                    "isApplying": isApplying,
                    "organizerState": String(describing: organizer.state)
                ])
                // #endregion
                // Reset isApplying after state change is complete
                // The view will switch to OrganizationResultView, but reset anyway for safety
                if case .completed = organizer.state {
                    isApplying = false
                }
            } catch {
                // #region agent log
                DebugLogger.log(hypothesisId: "D", location: "PreviewView.swift:112", message: "applyOrganization error", data: [
                    "error": error.localizedDescription,
                    "isApplying": isApplying
                ])
                // #endregion
                organizer.state = .error(error)
                isApplying = false
            }
        }
    }
}

struct FolderTreeView: View {
    let suggestion: FolderSuggestion
    let level: Int
    
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .frame(width: 20)
                
                Image(systemName: "folder")
                    .foregroundColor(.blue)
                
                Text(suggestion.folderName)
                    .fontWeight(.medium)
                
                Text("(\(suggestion.totalFileCount) files)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.leading, CGFloat(level * 20))
            
            if isExpanded {
                // Files in this folder
                ForEach(suggestion.files) { file in
                    HStack {
                        Image(systemName: "doc")
                            .foregroundColor(.secondary)
                        Text(file.displayName)
                        Spacer()
                        Text(file.formattedSize)
                            .foregroundColor(.secondary)
                    }
                    .padding(.leading, CGFloat((level + 1) * 20))
                }
                
                // Subfolders
                ForEach(suggestion.subfolders) { subfolder in
                    FolderTreeView(suggestion: subfolder, level: level + 1)
                }
            }
        }
    }
}

