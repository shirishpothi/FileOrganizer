//
//  AnalysisView.swift
//  FileOrganizer
//
//  Real-time analysis display with progress
//

import SwiftUI

struct AnalysisView: View {
    @EnvironmentObject var organizer: FolderOrganizer
    
    var body: some View {
        VStack(spacing: 30) {
            ProgressView(value: organizer.progress)
                .progressViewStyle(.linear)
                .frame(width: 400)
            
            if case .scanning = organizer.state {
                VStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    Text("Scanning directory...")
                        .font(.headline)
                }
            } else if case .analyzing = organizer.state {
                VStack(spacing: 10) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 50))
                        .foregroundColor(.purple)
                    Text("Analyzing with AI...")
                        .font(.headline)
                    Text("This may take a moment")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("\(Int(organizer.progress * 100))%")
                .font(.title3)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

