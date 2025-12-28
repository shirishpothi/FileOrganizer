//
//  OrganizationResultView.swift
//  FileOrganizer
//
//  Post-organization feedback view
//

import SwiftUI

struct OrganizationResultView: View {
    @EnvironmentObject var organizer: FolderOrganizer
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Organization Complete!")
                .font(.title)
                .fontWeight(.bold)
            
            if let plan = organizer.currentPlan {
                VStack(spacing: 10) {
                    Text("\(plan.totalFiles) files organized")
                    Text("\(plan.totalFolders) folders created")
                }
                .font(.body)
                .foregroundColor(.secondary)
            }
            
            Button("Organize Another Folder") {
                organizer.reset()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

