//
//  HistoryView.swift
//  FileOrganizer
//
//  Advanced History view with 4 stats, custom sidebar, and detailed reports
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var organizer: FolderOrganizer
    @State private var selectedEntry: OrganizationHistoryEntry?
    @State private var isProcessing = false
    @State private var alertMessage: String?
    @State private var showAlert = false
    @State private var selectedFilter: HistoryFilter = .all
    
    private var filteredEntries: [OrganizationHistoryEntry] {
        switch selectedFilter {
        case .all: return organizer.history.entries
        case .success: return organizer.history.entries.filter { $0.status == .completed }
        case .failed: return organizer.history.entries.filter { $0.status == .failed }
        case .skipped: return organizer.history.entries.filter { $0.status == .skipped || $0.status == .cancelled }
        }
    }
    
    enum HistoryFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case success = "Success"
        case failed = "Failed"
        case skipped = "Skipped"
        
        var id: String { rawValue }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Internal Sidebar (Sessions List)
            VStack(spacing: 0) {
                if organizer.history.entries.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title)
                            .foregroundStyle(.secondary)
                        Text("No History")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Quick Stats - 4 Cards
                    VStack(alignment: .leading, spacing: 12) {
                        Text("DASHBOARD")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                            .tracking(1)
                        
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                StatCard(title: "Sessions", value: "\(organizer.history.totalSessions)", icon: "list.bullet.rectangle", color: .gray)
                                StatCard(title: "Files", value: "\(organizer.history.totalFilesOrganized)", icon: "doc.on.doc", color: .blue)
                            }
                            HStack(spacing: 8) {
                                StatCard(title: "Folders", value: "\(organizer.history.totalFoldersCreated)", icon: "folder.fill.badge.plus", color: .purple)
                                StatCard(title: "Reverted", value: "\(organizer.history.revertedCount)", icon: "arrow.uturn.backward", color: .orange)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    
                    Divider()
                    
                    // Filter Bar
                    Picker("Filter", selection: $selectedFilter) {
                        ForEach(HistoryFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    
                    List(filteredEntries, selection: $selectedEntry) { entry in
                        HistoryEntryRow(entry: entry)
                            .tag(entry)
                            .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                    }
                    .listStyle(.inset)
                }
            }
            .frame(width: 400) // Increased width per user request
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Detail Area
            Group {
                if let entry = selectedEntry {
                    HistoryDetailView(entry: entry, isProcessing: $isProcessing, onAction: { msg in
                        alertMessage = msg
                        showAlert = true
                    })
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 48))
                            .foregroundStyle(.quaternary)
                        Text("Select a session to view detailed report")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("History")
        .disabled(isProcessing)
        .overlay {
            if isProcessing {
                ZStack {
                    Color.black.opacity(0.1)
                    ProgressView(organizer.organizationStage)
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(8)
                }
            }
        }
        .alert("History Action", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            if let msg = alertMessage {
                Text(msg)
            }
        }
    }
}

struct HistoryEntryRow: View {
    let entry: OrganizationHistoryEntry
    
    private var statusColor: Color {
        switch entry.status {
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .gray
        case .skipped: return .secondary
        case .undo: return .orange
        }
    }
    
    private var statusIcon: String {
        switch entry.status {
        case .completed: return "checkmark"
        case .failed: return "xmark"
        case .cancelled: return "stop.fill"
        case .skipped: return "arrow.right.circle"
        case .undo: return "arrow.uturn.backward"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: statusIcon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(statusColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(URL(fileURLWithPath: entry.directoryPath).lastPathComponent)
                    .font(.system(size: 14, weight: .semibold))
                    .strikethrough(entry.status == .undo)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    if entry.status == .completed {
                        Label("\(entry.filesOrganized) files", systemImage: "doc")
                            .font(.system(size: 11))
                        Label("\(entry.foldersCreated) folders", systemImage: "folder")
                            .font(.system(size: 11))
                    } else {
                        Text(entry.status.rawValue.capitalized)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(statusColor)
                    }
                    Spacer()
                    Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .opacity(entry.status == .undo || entry.status == .skipped ? 0.6 : 1.0)
    }
}

struct HistoryDetailView: View {
    let entry: OrganizationHistoryEntry
    @Binding var isProcessing: Bool
    let onAction: (String) -> Void
    @State private var showRawAIResponse = false
    
    @EnvironmentObject var organizer: FolderOrganizer
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Header
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.status == .completed ? "Organization Report" : "Session Detail")
                                .font(.title)
                                .fontWeight(.bold)
                            Text(entry.timestamp.formatted(date: .complete, time: .shortened))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        StatusBadge(status: entry.status)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label(entry.directoryPath, systemImage: "folder")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.primary)
                            .padding(8)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
                
                // Summary Stats in Detail
                if entry.success {
                    HStack(spacing: 20) {
                        DetailStatView(title: "Files Organized", value: "\(entry.filesOrganized)", icon: "doc.fill", color: .blue)
                        DetailStatView(title: "Folders Created", value: "\(entry.foldersCreated)", icon: "folder.fill", color: .purple)
                        if let plan = entry.plan {
                            DetailStatView(title: "Plan Version", value: "v\(plan.version)", icon: "number", color: .gray)
                        }
                    }
                }
                
                // Actions
                if entry.success {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Session Management")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            if entry.isUndone {
                                Button(action: handleRedo) {
                                    Label("Re-Apply This Organization", systemImage: "arrow.clockwise")
                                        .frame(minWidth: 150)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                            } else {
                                Button(action: handleUndo) {
                                    Label("Undo These Changes", systemImage: "arrow.uturn.backward")
                                        .frame(minWidth: 150)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                                
                                Button(action: handleRestore) {
                                    Label("Restore Folder to this State", systemImage: "clock.arrow.circlepath")
                                        .frame(minWidth: 150)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                            }
                        }
                    }
                }
                
                // Timeline Section
                if entry.success {
                    CompactTimelineView(
                        entries: organizer.history.entries,
                        directoryPath: entry.directoryPath
                    )
                }
                
                if !entry.success, let error = entry.errorMessage {
                    SectionView(title: "Error Log", icon: "exclamationmark.triangle.fill", color: .red) {
                        Text(error)
                            .font(.callout)
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.05))
                            .cornerRadius(8)
                    }
                }
                
                // Expanded Plan List with reasoning and files
                if let plan = entry.plan {
                    SectionView(title: "Organization Details", icon: "list.bullet.indent", color: .blue) {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(plan.suggestions) { suggestion in
                                FolderHistoryDetailRow(suggestion: suggestion)
                            }
                            
                            if !plan.unorganizedFiles.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Unorganized Files")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.orange)
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        ForEach(plan.unorganizedFiles) { fileItem in
                                            HStack {
                                                Image(systemName: "doc")
                                                Text(fileItem.displayName)
                                                Spacer()
                                            }
                                            .font(.caption)
                                            .padding(.leading, 12)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.orange.opacity(0.05))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                
                // Raw AI Data (New per user request)
                if let raw = entry.rawAIResponse {
                    DisclosureGroup("View Raw AI Response Data", isExpanded: $showRawAIResponse) {
                        Text(raw)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.black.opacity(0.05))
                            .cornerRadius(8)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(40)
        }
    }
    
    private func handleUndo() {
        processAction {
            try await organizer.undoHistoryEntry(entry)
            onAction("Operations reversed successfully.")
        }
    }
    
    private func handleRestore() {
        processAction {
            try await organizer.restoreToState(targetEntry: entry)
            onAction("Folder state restored.")
        }
    }
    
    private func handleRedo() {
        processAction {
            try await organizer.redoOrganization(from: entry)
            onAction("Organization re-applied.")
        }
    }
    
    private func processAction(_ action: @escaping () async throws -> Void) {
        isProcessing = true
        Task {
            do {
                try await action()
                isProcessing = false
            } catch {
                onAction("Error: \(error.localizedDescription)")
                isProcessing = false
            }
        }
    }
}

struct DetailStatView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(value)
                    .font(.headline)
            }
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(minWidth: 120, alignment: .leading)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(10)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                Text(title)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

struct StatusBadge: View {
    let status: OrganizationStatus
    
    private var color: Color {
        switch status {
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .gray
        case .skipped: return .secondary
        case .undo: return .orange
        }
    }
    
    var body: some View {
        Text(status.rawValue.uppercased())
            .font(.system(size: 12, weight: .bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(6)
    }
}

struct SectionView<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundColor(color)
            content()
        }
    }
}

struct FolderHistoryDetailRow: View {
    let suggestion: FolderSuggestion
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                isExpanded.toggle()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "folder.fill")
                        .foregroundColor(.blue)
                    
                    Text(suggestion.folderName)
                        .fontWeight(.semibold)
                    
                    Text("(\(suggestion.totalFileCount) files)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    if !suggestion.reasoning.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AI REASONING")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.purple)
                            Text(suggestion.reasoning)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(8)
                                .background(Color.purple.opacity(0.05))
                                .cornerRadius(6)
                        }
                    }
                    
                    // Files
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(suggestion.files) { fileItem in
                            HStack {
                                Image(systemName: "doc")
                                    .foregroundColor(.secondary)
                                Text(fileItem.displayName)
                                Spacer()
                                Text(fileItem.formattedSize)
                                    .foregroundStyle(.tertiary)
                            }
                            .font(.caption)
                            .padding(.leading, 12)
                        }
                    }
                    
                    // Subfolders
                    ForEach(suggestion.subfolders) { subfolder in
                        FolderHistoryDetailRow(suggestion: subfolder)
                            .padding(.leading, 12)
                    }
                }
                .padding(.leading, 12)
                .padding(.vertical, 4)
            }
        }
        .padding(12)
        .background(Color.secondary.opacity(0.03))
        .cornerRadius(8)
    }
}
