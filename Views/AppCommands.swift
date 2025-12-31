//
//  AppCommands.swift
//  FileOrganizer
//
//  Comprehensive menu bar commands with keyboard shortcuts
//

import SwiftUI
import Combine

// MARK: - App Commands

public struct FileOrganizerCommands: Commands {
    @ObservedObject var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some Commands {
        // Replace default New/Open with custom commands
        CommandGroup(replacing: .newItem) {
            Button("New Session") {
                appState.resetSession()
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("Open Directory...") {
                appState.showDirectoryPicker = true
            }
            .keyboardShortcut("o", modifiers: .command)

            Divider()

            Button("Export Results...") {
                appState.exportResults()
            }
            .keyboardShortcut("e", modifiers: .command)
            .disabled(!appState.hasResults)
        }

        // Edit menu additions
        CommandGroup(after: .pasteboard) {
            Divider()

            Button("Select All Files") {
                appState.selectAllFiles()
            }
            .keyboardShortcut("a", modifiers: .command)
            .disabled(!appState.hasFiles)
        }

        // View menu
        CommandMenu("View") {
            Button(appState.showingSidebar ? "Hide Sidebar" : "Show Sidebar") {
                appState.showingSidebar.toggle()
            }
            .keyboardShortcut("\\", modifiers: .command)

            Divider()

            Button("Settings") {
                appState.currentView = .settings
            }
            .keyboardShortcut(",", modifiers: .command)

            Button("History") {
                appState.currentView = .history
            }
            .keyboardShortcut("h", modifiers: [.command, .shift])

            Button("Organize") {
                appState.currentView = .organize
            }
            .keyboardShortcut("1", modifiers: .command)

            Divider()

            Button("Workspace Health") {
                appState.currentView = .workspaceHealth
            }
            .keyboardShortcut("2", modifiers: .command)

            Button("Duplicates") {
                appState.currentView = .duplicates
            }
            .keyboardShortcut("3", modifiers: .command)

            Button("Exclusions") {
                appState.currentView = .exclusions
            }
            .keyboardShortcut("4", modifiers: .command)

            Button("Watched Folders") {
                appState.currentView = .watchedFolders
            }
            .keyboardShortcut("5", modifiers: .command)
        }

        // Organize menu
        CommandMenu("Organize") {
            Button("Start Organization") {
                appState.startOrganization()
            }
            .keyboardShortcut("r", modifiers: .command)
            .disabled(!appState.canStartOrganization)

            Button("Regenerate Organization") {
                appState.regenerateOrganization()
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
            .disabled(!appState.hasCurrentPlan)

            Divider()

            Button("Apply Changes") {
                appState.applyChanges()
            }
            .keyboardShortcut(.return, modifiers: .command)
            .disabled(!appState.canApply)

            Button("Preview Changes") {
                appState.previewChanges()
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])
            .disabled(!appState.hasCurrentPlan)

            Divider()

            Button("Cancel") {
                appState.cancelOperation()
            }
            .keyboardShortcut(.escape, modifiers: [])
            .disabled(!appState.isOperationInProgress)
        }

        // Help menu additions
        CommandGroup(replacing: .help) {
            Button("FileOrganizer Help") {
                appState.showHelp()
            }
            .keyboardShortcut("?", modifiers: .command)

            Divider()

            Link("GitHub Repository", destination: URL(string: "https://github.com")!)

            Divider()

            Button("About FileOrganizer") {
                appState.showAbout()
            }
        }
    }
}

// MARK: - App State

@MainActor
public class AppState: ObservableObject {
    @Published public var currentView: AppView = .organize
    @Published public var showingSidebar: Bool = true
    @Published public var showDirectoryPicker: Bool = false
    @Published public var selectedDirectory: URL?

    // State derived from FolderOrganizer
    public weak var organizer: FolderOrganizer?
    public var calibrateAction: ((WatchedFolder) -> Void)?

    public enum AppView: Equatable, Sendable {
        case settings
        case organize
        case history
        case workspaceHealth
        case duplicates
        case exclusions
        case watchedFolders
    }

    public init() {}

    public var hasResults: Bool {
        organizer?.currentPlan != nil && organizer?.state == .completed
    }

    public var hasFiles: Bool {
        organizer?.currentPlan != nil
    }

    public var canStartOrganization: Bool {
        selectedDirectory != nil && (organizer?.state == .idle || organizer?.state == .completed)
    }

    public var hasCurrentPlan: Bool {
        organizer?.currentPlan != nil
    }

    public var canApply: Bool {
        organizer?.state == .ready
    }

    public var isOperationInProgress: Bool {
        guard let state = organizer?.state else { return false }
        switch state {
        case .scanning, .organizing, .applying:
            return true
        default:
            return false
        }
    }

    public func resetSession() {
        selectedDirectory = nil
        organizer?.reset()
    }

    public func exportResults() {
        // TODO: Implement export functionality
    }

    public func selectAllFiles() {
        // TODO: Implement select all
    }

    public func startOrganization() {
        guard let organizer = organizer, let directory = selectedDirectory else { return }
        Task {
            try? await organizer.organize(directory: directory)
        }
    }

    public func regenerateOrganization() {
        guard let organizer = organizer else { return }
        Task {
            try? await organizer.regeneratePreview()
        }
    }

    public func applyChanges() {
        guard let organizer = organizer, let directory = selectedDirectory else { return }
        Task {
            try? await organizer.apply(at: directory)
        }
    }

    public func previewChanges() {
        // Navigation to preview is handled by view logic
    }

    public func cancelOperation() {
        organizer?.reset()
    }

    public func showHelp() {
        if let url = URL(string: "https://github.com") {
            NSWorkspace.shared.open(url)
        }
    }

    public func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
    }
}
