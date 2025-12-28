//
//  AIClientProtocol.swift
//  FileOrganizer
//
//  Protocol defining AI client interface
//

import Foundation

protocol AIClientProtocol {
    func analyze(files: [FileItem]) async throws -> OrganizationPlan
    var config: AIConfig { get }
}

