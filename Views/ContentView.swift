//
//  ContentView.swift
//  FileOrganizer
//
//  Main container view with full-width layout
//  Updated to include Workspace Health and Duplicates navigation
//

import SwiftUI

public struct ContentView: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var organizer: FolderOrganizer
    @EnvironmentObject var exclusionRules: ExclusionRulesManager
    @EnvironmentObject var extensionListener: ExtensionListener

    public init() {}

    public var body: some View {
        NavigationSplitView(columnVisibility: Binding(
            get: { appState.showingSidebar ? .all : .detailOnly },
            set: { appState.showingSidebar = $0 != .detailOnly }
        )) {
            // Sidebar
            List(selection: Binding(
                get: { appState.currentView },
                set: { appState.currentView = $0 ?? .organize }
            )) {
                Section("Main") {
                    NavigationLink(value: AppState.AppView.organize) {
                        Label("Organize", systemImage: "folder.badge.gearshape")
                    }
                    .accessibilityIdentifier("OrganizeSidebarItem")

                    NavigationLink(value: AppState.AppView.workspaceHealth) {
                        Label("Workspace Health", systemImage: "heart.text.square")
                    }
                    .accessibilityIdentifier("WorkspaceHealthSidebarItem")

                    NavigationLink(value: AppState.AppView.duplicates) {
                        Label("Duplicates", systemImage: "doc.on.doc")
                    }
                    .accessibilityIdentifier("DuplicatesSidebarItem")
                }

                Section("Options") {
                    NavigationLink(value: AppState.AppView.settings) {
                        Label("Settings", systemImage: "gear")
                    }
                    .accessibilityIdentifier("SettingsSidebarItem")

                    NavigationLink(value: AppState.AppView.history) {
                        Label("History", systemImage: "clock")
                    }
                    .accessibilityIdentifier("HistorySidebarItem")

                    NavigationLink(value: AppState.AppView.exclusions) {
                        Label("Exclusions", systemImage: "eye.slash")
                    }
                    .accessibilityIdentifier("ExclusionsSidebarItem")

                    NavigationLink(value: AppState.AppView.watchedFolders) {
                        Label("Watched Folders", systemImage: "eye")
                    }
                    .accessibilityIdentifier("WatchedFoldersSidebarItem")
                }
            }
            .navigationTitle("FileOrganizer")
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 300)
        } detail: {
            // Main content area - uses full width
            Group {
                switch appState.currentView {
                case .organize:
                    OrganizeView()
                case .settings:
                    SettingsView()
                case .history:
                    HistoryView()
                case .workspaceHealth:
                    WorkspaceHealthView()
                case .duplicates:
                    DuplicatesView()
                case .exclusions:
                    ExclusionRulesView()
                case .watchedFolders:
                    WatchedFoldersView()
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Main Navigation")
        .frame(minWidth: 1000, minHeight: 700)
        .onChange(of: appState.showDirectoryPicker) { oldValue, showPicker in
            if showPicker {
                openDirectoryPicker()
            }
        }
        .onReceive(extensionListener.$incomingURL) { url in
            if let url = url {
                appState.selectedDirectory = url
                appState.currentView = .organize
                extensionListener.incomingURL = nil
            }
        }
    }

    private func openDirectoryPicker() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Select a directory to organize"
        panel.prompt = "Select"

        if panel.runModal() == .OK, let url = panel.url {
            appState.selectedDirectory = url
        }

        appState.showDirectoryPicker = false
    }
}
