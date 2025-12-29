//
//  AIClientProtocol.swift
//  FileOrganizer
//
//  Protocol defining AI client interface
//

import Foundation

protocol AIClientProtocol: Sendable {
    func analyze(files: [FileItem], customInstructions: String?, personaPrompt: String?, temperature: Double?) async throws -> OrganizationPlan
    var config: AIConfig { get }
}

