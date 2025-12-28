//
//  ExtensionListener.swift
//  FileOrganizer
//
//  Listens for Finder extension notifications
//

import Foundation
import SwiftUI

public class ExtensionListener: ObservableObject {
    @Published public var incomingURL: URL?
    
    public init() {
        ExtensionCommunication.setupNotificationObserver { [weak self] url in
            DispatchQueue.main.async {
                self?.incomingURL = url
            }
        }
    }
}
