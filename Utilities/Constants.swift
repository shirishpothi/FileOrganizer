//
//  Constants.swift
//  FileOrganizer
//
//  App-wide constants
//

import Foundation

enum Constants {
    static let appGroupIdentifier = "group.com.fileorganizer.app"
    static let maxPreviewVersions = 5
    static let largeOperationThreshold = 1000
}

extension Notification.Name {
    public static let organizationDidStart = Notification.Name("OrganizationDidStart")
    public static let organizationDidFinish = Notification.Name("OrganizationDidFinish")
    public static let organizationDidRevert = Notification.Name("OrganizationDidRevert")
}


