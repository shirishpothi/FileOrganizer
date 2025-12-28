//
//  ContentView.swift
//  FileOrganizer
//
//  Main container view
//

import SwiftUI

public struct ContentView: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @StateObject private var organizer = FolderOrganizer()
    @StateObject private var exclusionRules = ExclusionRulesManager()
    @StateObject private var extensionListener = ExtensionListener()
    @State private var selectedTab = 0
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(0)
            
            OrganizeView()
                .environmentObject(organizer)
                .tabItem {
                    Label("Organize", systemImage: "folder")
                }
                .tag(1)
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock")
                }
                .tag(2)
        }
        .frame(minWidth: 900, minHeight: 700)
        .onAppear {
            organizer.exclusionRules = exclusionRules
            // Check for pending directory from extension
            if ExtensionCommunication.receiveFromExtension() != nil {
                selectedTab = 1
            }
        }
        .onReceive(extensionListener.$incomingURL) { url in
            if url != nil {
                self.selectedTab = 1
                extensionListener.incomingURL = nil
            }
        }
    }
}

