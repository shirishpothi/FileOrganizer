//
//  HistoryView.swift
//  FileOrganizer
//
//  Organization history view
//

import SwiftUI

struct HistoryView: View {
    @StateObject private var history = OrganizationHistory()
    
    var body: some View {
        NavigationView {
            VStack {
                if history.entries.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "clock")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No organization history")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section("Statistics") {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Total Files Organized")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(history.totalFilesOrganized)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("Total Folders Created")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(history.totalFoldersCreated)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        
                        Section("History") {
                            ForEach(history.entries) { entry in
                                HistoryEntryRow(entry: entry)
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                if !history.entries.isEmpty {
                    Button("Clear") {
                        history.clearHistory()
                    }
                }
            }
        }
    }
}

struct HistoryEntryRow: View {
    let entry: OrganizationHistoryEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: entry.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(entry.success ? .green : .red)
                
                Text(entry.directoryPath)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Text(entry.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("\(entry.filesOrganized) files", systemImage: "doc")
                Spacer()
                Label("\(entry.foldersCreated) folders", systemImage: "folder")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

