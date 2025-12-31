//
//  GenerationStatsView.swift
//  FileOrganizer
//
//  Created by Antigravity on 12/31/25.
//

import SwiftUI

struct GenerationStatsView: View {
    let stats: GenerationStats
    
    var body: some View {
        HStack(spacing: 20) {
            StatItem(label: "Tokens/Sec", value: String(format: "%.1f", stats.tps))
            Divider().frame(height: 20)
            StatItem(label: "Time to First Token", value: String(format: "%.2fs", stats.ttft))
            Divider().frame(height: 20)
            StatItem(label: "Total Duration", value: String(format: "%.2fs", stats.duration))
            Divider().frame(height: 20)
            StatItem(label: "Est. Tokens", value: "\(stats.totalTokens)")
            Divider().frame(height: 20)
            StatItem(label: "Model", value: stats.model, isMonospaced: false)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
    }
}

struct StatItem: View {
    let label: String
    let value: String
    var isMonospaced: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            Text(value)
                .font(isMonospaced ? .system(.caption, design: .monospaced) : .caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}
