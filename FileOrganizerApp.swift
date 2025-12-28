//
//  FileOrganizerApp.swift
//  FileOrganizer
//
//  Created on macOS
//

import SwiftUI
import FileOrganizerLib

@main
struct FileOrganizerApp: App {
    @StateObject private var settingsViewModel = SettingsViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settingsViewModel)
        }
        .windowStyle(.automatic)
        .defaultSize(width: 900, height: 700)
    }
}

