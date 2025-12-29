//
//  DuplicatesView.swift
//  FileOrganizer
//
//  UI for displaying and managing duplicate files
//

import SwiftUI

struct DuplicatesView: View {
    @StateObject private var detectionManager = DuplicateDetectionManager()
    @EnvironmentObject var appState: AppState
    @State private var selectedGroup: DuplicateGroup?
    @State private var showDeleteConfirmation = false
    @State private var filesToDelete: [FileItem] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            DuplicatesHeader(
                manager: detectionManager,
                onScan: startScan,
                onBulkDelete: { keepNewest in
                    prepareBulkDelete(keepNewest: keepNewest)
                }
            )
            
            Divider()
            
            // Content
            if detectionManager.isScanning {
                ScanProgressView(progress: detectionManager.scanProgress)
            } else if detectionManager.duplicateGroups.isEmpty {
                EmptyDuplicatesView(hasScanned: detectionManager.lastScanDate != nil)
            } else {
                DuplicatesList(
                    groups: detectionManager.duplicateGroups,
                    selectedGroup: $selectedGroup,
                    onDelete: { files in
                        filesToDelete = files
                        showDeleteConfirmation = true
                    }
                )
            }
        }
        .navigationTitle("Duplicate Files")
        .alert("Delete Duplicate Files?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteFiles(filesToDelete)
            }
        } message: {
            Text("This will permanently delete \(filesToDelete.count) file(s). This cannot be undone.")
        }
    }
    
    private func startScan() {
        guard let directory = appState.selectedDirectory else { return }
        
        Task {
            let scanner = DirectoryScanner()
            do {
                let files = try await scanner.scanDirectory(at: directory, computeHashes: true)
                await detectionManager.scanForDuplicates(files: files)
            } catch {
                DebugLogger.log("Duplicate scan failed: \(error)")
            }
        }
    }
    
    private func deleteFiles(_ files: [FileItem]) {
        let fm = FileManager.default
        for file in files {
            try? fm.removeItem(atPath: file.path)
        }
        // Refresh scan
        startScan()
    }
    
    private func prepareBulkDelete(keepNewest: Bool) {
        var filesToDelete: [FileItem] = []
        
        for group in detectionManager.duplicateGroups {
            // Sort files based on criteria
            let sortedFiles = group.files.sorted { f1, f2 in
                let d1 = f1.creationDate ?? Date.distantPast
                let d2 = f2.creationDate ?? Date.distantPast
                return keepNewest ? (d1 > d2) : (d1 < d2)
            }
            
            // Keep the first one (best match for criteria), delete the rest
            if sortedFiles.count > 1 {
                filesToDelete.append(contentsOf: sortedFiles.dropFirst())
            }
        }
        
        if !filesToDelete.isEmpty {
            self.filesToDelete = filesToDelete
            self.showDeleteConfirmation = true
        }
    }
}

// MARK: - Header

struct DuplicatesHeader: View {
    @ObservedObject var manager: DuplicateDetectionManager
    let onScan: () -> Void
    let onBulkDelete: (Bool) -> Void // Bool: keepNewest
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Duplicate Files")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if !manager.duplicateGroups.isEmpty {
                    Text("Found \(manager.totalDuplicates) duplicates • \(manager.formattedSavings) recoverable")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let lastScan = manager.lastScanDate {
                Text("Last scan: \(lastScan, style: .relative) ago")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.6))
            }
            
            if !manager.duplicateGroups.isEmpty {
                Menu {
                    Button {
                        onBulkDelete(true)
                    } label: {
                        Label("Delete All (Keep Newest)", systemImage: "clock")
                    }
                    
                    Button {
                        onBulkDelete(false)
                    } label: {
                        Label("Delete All (Keep Oldest)", systemImage: "clock.arrow.circlepath")
                    }
                } label: {
                    Label("Cleanup", systemImage: "trash")
                }
                .disabled(manager.isScanning)
            }
            
            Button(action: onScan) {
                Label("Scan for Duplicates", systemImage: "doc.on.doc.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(manager.isScanning)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Scan Progress

struct ScanProgressView: View {
    let progress: Double
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .frame(width: 300)
            
            Text("Scanning files... \(Int(progress * 100))%")
                .font(.body)
                .foregroundColor(.secondary)
            
            Text("Computing file hashes to find duplicates")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty State

struct EmptyDuplicatesView: View {
    let hasScanned: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: hasScanned ? "checkmark.circle" : "doc.on.doc")
                .font(.system(size: 48))
                .foregroundStyle(hasScanned ? .green : .secondary)
            
            if hasScanned {
                Text("No Duplicates Found")
                    .font(.headline)
                Text("All files in this folder are unique")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Find Duplicate Files")
                    .font(.headline)
                Text("Scan your folder to identify files with identical content")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Duplicates List

struct DuplicatesList: View {
    let groups: [DuplicateGroup]
    @Binding var selectedGroup: DuplicateGroup?
    let onDelete: ([FileItem]) -> Void
    
    var body: some View {
        List(groups, selection: $selectedGroup) { group in
            DuplicateGroupRow(
                group: group,
                onDeleteDuplicates: { keepFirst in
                    let toDelete = keepFirst ? Array(group.files.dropFirst()) : Array(group.files.dropLast())
                    onDelete(toDelete)
                }
            )
            .tag(group)
        }
        .listStyle(.inset)
    }
}

// MARK: - Duplicate Group Row

struct DuplicateGroupRow: View {
    let group: DuplicateGroup
    let onDeleteDuplicates: (Bool) -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                
                Image(systemName: "doc.on.doc.fill")
                    .foregroundColor(.orange)
                
                Text("\(group.files.count) identical files")
                    .fontWeight(.medium)
                
                Text("• \(ByteCountFormatter.string(fromByteCount: group.files.first?.size ?? 0, countStyle: .file)) each")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Save \(ByteCountFormatter.string(fromByteCount: group.potentialSavings, countStyle: .file))")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(4)
            }
            
            // Expanded file list
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(group.files.enumerated()), id: \.element.id) { index, file in
                        HStack {
                            if index == 0 {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundColor(.yellow)
                            } else {
                                Image(systemName: "doc")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(file.displayName)
                                .font(.caption)
                            
                            Spacer()
                            
                            Text(file.path)
                                .font(.caption2)
                                .foregroundColor(.secondary.opacity(0.6))
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        .padding(.leading, 24)
                    }
                    
                    HStack {
                        Spacer()
                        
                        Button("Keep First, Delete Others") {
                            onDeleteDuplicates(true)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    DuplicatesView()
        .environmentObject(AppState())
        .frame(width: 700, height: 500)
}

// MARK: - AppState Extension (if not exists)
// Note: Add selectedDirectory to AppState if not already present
