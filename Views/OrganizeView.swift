//
//  OrganizeView.swift
//  FileOrganizer
//
//  Main organization workflow view
//

import SwiftUI




struct OrganizeView: View {
    @EnvironmentObject var organizer: FolderOrganizer
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @StateObject private var extensionListener = ExtensionListener()
    @State private var selectedDirectory: URL?
    @State private var showDirectoryPicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if selectedDirectory == nil {
                    DirectorySelectionView(selectedDirectory: $selectedDirectory)
                } else if case .idle = organizer.state {
                    Button("Start Organization") {
                        startOrganization()
                    }
                    .buttonStyle(.borderedProminent)
                } else if case .scanning = organizer.state {
                    AnalysisView()
                } else if case .analyzing = organizer.state {
                    AnalysisView()
                } else if case .ready = organizer.state, let plan = organizer.currentPlan {
                    PreviewView(plan: plan, baseURL: selectedDirectory!)
                } else if case .completed = organizer.state {
                    OrganizationResultView()
                } else if case .error(let error) = organizer.state {
                    VStack {
                        Text("Error: \(error.localizedDescription)")
                        Button("Retry") {
                            organizer.reset()
                        }
                    }
                }
            }
            .navigationTitle("Organize Files")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            configureOrganizer()
            // setupExtensionListener() - Remvoed
            // Check for directory from Finder extension
            if selectedDirectory == nil, let directoryURL = ExtensionCommunication.receiveFromExtension() {
                selectedDirectory = directoryURL
            }
        }
        .onReceive(extensionListener.$incomingURL) { url in
            if let url = url {
                self.selectedDirectory = url
                // Logic to start organization
                if case .idle = organizer.state {
                    startOrganization()
                }
                extensionListener.incomingURL = nil // Reset
            }
        }
    }
    

    
    private func configureOrganizer() {
        do {
            try organizer.configure(with: settingsViewModel.config)
        } catch {
            organizer.state = .error(error)
        }
    }
    
    private func startOrganization() {
        // #region agent log
        DebugLogger.log(hypothesisId: "C", location: "OrganizeView.swift:74", message: "startOrganization called", data: [
            "selectedDirectory": selectedDirectory?.path ?? "nil"
        ])
        // #endregion
        guard let directory = selectedDirectory else {
            // #region agent log
            DebugLogger.log(hypothesisId: "C", location: "OrganizeView.swift:76", message: "startOrganization early return - no directory", data: [:])
            // #endregion
            return
        }
        
        Task {
            do {
                try await organizer.organize(directory: directory)
            } catch {
                organizer.state = .error(error)
            }
        }
    }
}

