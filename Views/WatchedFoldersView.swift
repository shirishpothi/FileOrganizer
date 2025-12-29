//
//  WatchedFoldersView.swift
//  FileOrganizer
//
//  Settings view for managing watched folders
//

import SwiftUI

struct WatchedFoldersView: View {
    @EnvironmentObject var watchedFoldersManager: WatchedFoldersManager
    @State private var showingFolderPicker = false
    @State private var selectedFolderForEdit: WatchedFolder?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Watched Folders")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Automatically organize new files as they arrive")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    showingFolderPicker = true
                } label: {
                    Label("Add Folder", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Folder List
            if watchedFoldersManager.folders.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "eye.slash")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)
                    
                    Text("No Watched Folders")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Add folders like Downloads or Desktop to automatically organize new files")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 300)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(watchedFoldersManager.folders) { folder in
                        WatchedFolderRow(folder: folder)
                            .contextMenu {
                                Button("Remove") {
                                    watchedFoldersManager.removeFolder(folder)
                                }
                            }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            watchedFoldersManager.removeFolder(watchedFoldersManager.folders[index])
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .fileImporter(
            isPresented: $showingFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    let folder = WatchedFolder(path: url.path)
                    watchedFoldersManager.addFolder(folder)
                }
            case .failure(let error):
                DebugLogger.log("Failed to select folder: \(error)")
            }
        }
    }
}

struct WatchedFolderRow: View {
    let folder: WatchedFolder
    @EnvironmentObject var watchedFoldersManager: WatchedFoldersManager
    @State private var showingConfig = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Folder Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(folder.isEnabled ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "folder.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(folder.isEnabled ? .blue : .gray)
            }
            
            // Folder Info
            VStack(alignment: .leading, spacing: 4) {
                Text(folder.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(folder.isEnabled ? .primary : .secondary)
                
                Text(folder.path)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                if let lastTriggered = folder.lastTriggered {
                    Text("Last organized: \(lastTriggered, style: .relative) ago")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }
            
            Spacer()
            
            // Controls
            VStack(alignment: .trailing, spacing: 8) {
                Toggle("", isOn: Binding(
                    get: { folder.isEnabled },
                    set: { _ in watchedFoldersManager.toggleEnabled(for: folder) }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
                
                if folder.isEnabled {
                    HStack(spacing: 4) {
                        Image(systemName: folder.autoOrganize ? "wand.and.stars" : "wand.and.stars.inverse")
                            .font(.system(size: 10))
                        Text(folder.autoOrganize ? "Auto" : "Manual")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(folder.autoOrganize ? .green : .secondary)
                    .onTapGesture {
                        watchedFoldersManager.toggleAutoOrganize(for: folder)
                    }
                }
                
                Button {
                    showingConfig = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showingConfig) {
                    WatchedFolderConfigView(folder: folder)
                }
            }
        }
        .padding(.vertical, 8)
        .opacity(folder.exists ? 1.0 : 0.5)
        .overlay {
            if !folder.exists {
                HStack {
                    Spacer()
                    Text("Folder not found")
                        .font(.caption2)
                        .foregroundColor(.red)
                        .padding(4)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
    }
}

#Preview {
    WatchedFoldersView()
        .environmentObject(WatchedFoldersManager())
        .frame(width: 500, height: 400)
}

struct WatchedFolderConfigView: View {
    let folder: WatchedFolder
    @EnvironmentObject var watchedFoldersManager: WatchedFoldersManager
    @Environment(\.dismiss) var dismiss
    
    @State private var customPrompt: String
    @State private var temperature: Double
    @State private var autoOrganize: Bool
    
    init(folder: WatchedFolder) {
        self.folder = folder
        _customPrompt = State(initialValue: folder.customPrompt ?? "")
        _temperature = State(initialValue: folder.temperature ?? 0.7)
        _autoOrganize = State(initialValue: folder.autoOrganize)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Organization Strategy") {
                    Toggle("Auto-Organize", isOn: $autoOrganize)
                    Text("Automatically organize files when changes are detected.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section("Custom Instructions") {
                    TextEditor(text: $customPrompt)
                        .font(.system(.body, design: .monospaced))
                        .frame(height: 100)
                    Text("Overrides generic instructions for this folder only.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section("Creativity (Temperature)") {
                    HStack {
                        Text("Focused")
                            .font(.caption)
                        Slider(value: $temperature, in: 0...1)
                        Text("Creative")
                            .font(.caption)
                    }
                    Text("Current: \(temperature, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(folder.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                }
            }
        }
    }
    
    private func save() {
        var updated = folder
        updated.customPrompt = customPrompt.isEmpty ? nil : customPrompt
        updated.temperature = temperature
        updated.autoOrganize = autoOrganize
        watchedFoldersManager.updateFolder(updated)
        dismiss()
    }
}
