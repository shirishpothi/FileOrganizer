//
//  AnalysisView.swift
//  FileOrganizer
//
//  Real-time organization display with streaming progress
//

import SwiftUI

struct AnalysisView: View {
    @EnvironmentObject var organizer: FolderOrganizer
    
    var body: some View {
        VStack(spacing: 24) {
            // Progress indicator
            VStack(spacing: 16) {
                ProgressView(value: organizer.progress)
                    .progressViewStyle(.linear)
                    .frame(maxWidth: 500)
                
                Text("\(Int(organizer.progress * 100))%")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }
            
            // Stage indicator with icon
            HStack(spacing: 12) {
                if case .scanning = organizer.state {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundStyle(.blue)
                        .symbolEffect(.pulse)
                } else if case .organizing = organizer.state {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 32))
                        .foregroundStyle(.purple)
                        .symbolEffect(.variableColor.iterative)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(organizer.organizationStage)
                        .font(.headline)
                    
                    if organizer.isStreaming {
                        Text("Receiving response...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Elapsed time
                    if organizer.elapsedTime > 0 {
                        Text("Elapsed: \(formatTime(organizer.elapsedTime))")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .monospacedDigit()
                    }
                }
            }
            
            // Timeout message
            if organizer.showTimeoutMessage {
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Taking longer than expected", systemImage: "clock")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("AI organization can take a while depending on the number of files, model speed, and network conditions. For large directories, this may take a few minutes.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if organizer.elapsedTime > 60 {
                            Text("Tip: Consider organizing smaller directories first, or check your AI provider settings.")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                    .frame(maxWidth: 400)
                }
                .backgroundStyle(.yellow.opacity(0.1))
            }
            
            // Streaming content preview (if available)
            if organizer.isStreaming && !organizer.streamingContent.isEmpty {
                GroupBox {
                    ScrollView {
                        ScrollViewReader { proxy in
                            VStack(alignment: .leading, spacing: 0) {
                                Text(truncatedStreamContent)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                                    .id("bottom")
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .onChange(of: organizer.streamingContent) { oldValue, newValue in
                                withAnimation {
                                    proxy.scrollTo("bottom", anchor: .bottom)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: 600, maxHeight: 200)
                } label: {
                    Label("AI Response", systemImage: "text.word.spacing")
                        .font(.caption)
                }
            }
            
            // Cancel button
            Button("Cancel") {
                organizer.reset()
            }
            .buttonStyle(.bordered)
            .keyboardShortcut(.escape, modifiers: [])
        }
    }
    
    private var truncatedStreamContent: String {
        let content = organizer.streamingContent
        if content.count > 1000 {
            let start = content.index(content.endIndex, offsetBy: -1000)
            return "..." + String(content[start...])
        }
        return content
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}

