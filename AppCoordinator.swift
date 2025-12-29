//
//  AppCoordinator.swift
//  FileOrganizer
//
//  Coordinates background tasks and watched folder automation
//

import Foundation
import SwiftUI
#if canImport(FileOrganizerLib)
import FileOrganizerLib
#endif

@MainActor
class AppCoordinator: ObservableObject, FolderWatcherDelegate {
    let folderWatcher = FolderWatcher()
    let organizer: FolderOrganizer
    let watchedFoldersManager: WatchedFoldersManager
    
    init(organizer: FolderOrganizer, watchedFoldersManager: WatchedFoldersManager) {
        self.organizer = organizer
        self.watchedFoldersManager = watchedFoldersManager
        self.folderWatcher.delegate = self
        
        // Initial sync
        self.folderWatcher.syncWithFolders(watchedFoldersManager.folders)
    }
    
    func folderWatcher(_ watcher: FolderWatcher, didDetectChangesIn folder: WatchedFolder) {
        print("Detailed Log: Change detected in \(folder.path)")
        
        Task {
            // Check if we can proceed (e.g. not already organizing)
            guard organizer.state == .idle || organizer.state == .ready || organizer.state == .completed else {
                print("Detailed Log: Organizer busy, skipping auto-organization")
                return
            }
            
            do {
                print("Detailed Log: Starting auto-organization for \(folder.name)")
                
                // Configure if needed (assuming already configured by UI/App)
                // We just trigger organization
                
                // Ideally, we'd have a separate "background" organizer/session to not hijack the UI,
                // but for this app, hijacking the UI to show progress is probably expected behavior for now.
                
                watchedFoldersManager.markTriggered(folder)
                try await organizer.organize(
                    directory: folder.url, 
                    customPrompt: folder.customPrompt,
                    temperature: folder.temperature
                )
                
                // If it's a "silent" auto-organize, we might want to apply automatically, 
                // but for safety we'll stop at "Ready" state so user can review.
                // If the user wants fully automatic "Apply", that would be a new setting "Auto-Apply".
                // For now, getting it to "Ready" is a good step.
                
            } catch {
                print("Detailed Log: Auto-organization failed: \(error.localizedDescription)")
            }
        }
    }
    
    func syncWatchedFolders() {
        folderWatcher.syncWithFolders(watchedFoldersManager.folders)
    }
}
