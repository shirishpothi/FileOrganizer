//
//  FolderWatcher.swift
//  FileOrganizer
//
//  Monitors directories for file system changes using DispatchSourceFileSystemObject
//

import Foundation

/// Protocol for receiving folder change notifications
@MainActor
public protocol FolderWatcherDelegate: AnyObject {
    func folderWatcher(_ watcher: FolderWatcher, didDetectChangesIn folder: WatchedFolder)
}

/// Monitors directories for file changes and triggers organization
public final class FolderWatcher: @unchecked Sendable {
    @MainActor public weak var delegate: FolderWatcherDelegate?
    
    private var sources: [UUID: DispatchSourceFileSystemObject] = [:]
    private var fileDescriptors: [UUID: Int32] = [:]
    private var debounceTimers: [UUID: DispatchWorkItem] = [:]
    private let queue = DispatchQueue(label: "com.fileorganizer.folderwatcher", qos: .utility)
    
    public init() {}
    
    deinit {
        stopAllWatching()
    }
    
    /// Start watching a folder for changes
    public func startWatching(_ folder: WatchedFolder) {
        guard folder.isEnabled else { return }
        
        // Stop existing watcher for this folder if any
        stopWatching(folder)
        
        let path = folder.path
        let fd = open(path, O_EVTONLY)
        
        guard fd >= 0 else {
            DebugLogger.log("Failed to open file descriptor for: \(path)")
            return
        }
        
        fileDescriptors[folder.id] = fd
        
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .delete, .rename, .extend],
            queue: queue
        )
        
        source.setEventHandler { [weak self] in
            self?.handleEvent(for: folder)
        }
        
        source.setCancelHandler { [weak self] in
            if let fd = self?.fileDescriptors[folder.id] {
                close(fd)
            }
            self?.fileDescriptors.removeValue(forKey: folder.id)
        }
        
        sources[folder.id] = source
        source.resume()
        
        DebugLogger.log("Started watching: \(folder.name)")
    }
    
    /// Stop watching a specific folder
    public func stopWatching(_ folder: WatchedFolder) {
        stopWatching(id: folder.id)
    }
    
    private func stopWatching(id: UUID) {
        // Cancel debounce timer
        debounceTimers[id]?.cancel()
        debounceTimers.removeValue(forKey: id)
        
        // Cancel and release source
        if let source = sources[id] {
            source.cancel()
            sources.removeValue(forKey: id)
        }
    }
    
    /// Stop watching all folders
    public func stopAllWatching() {
        for (id, _) in sources {
            stopWatching(id: id)
        }
    }
    
    /// Update watched folders based on provided list
    public func syncWithFolders(_ folders: [WatchedFolder]) {
        let currentIds = Set(sources.keys)
        let folderIds = Set(folders.map { $0.id })
        
        // Stop watching folders that were removed
        for id in currentIds.subtracting(folderIds) {
            stopWatching(id: id)
        }
        
        // Start or update watching for current folders
        for folder in folders {
            if folder.isEnabled {
                if sources[folder.id] == nil {
                    startWatching(folder)
                }
            } else {
                stopWatching(folder)
            }
        }
    }
    
    // MARK: - Private
    
    private func handleEvent(for folder: WatchedFolder) {
        guard folder.autoOrganize else { return }
        
        // Debounce: cancel previous timer and start new one
        debounceTimers[folder.id]?.cancel()
        
        let delay = folder.triggerDelay
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            Task { @MainActor in
                self.delegate?.folderWatcher(self, didDetectChangesIn: folder)
            }
        }
        
        debounceTimers[folder.id] = workItem
        queue.asyncAfter(deadline: .now() + delay, execute: workItem)
        
        DebugLogger.log("Change detected in \(folder.name), will trigger in \(delay)s")
    }
}
