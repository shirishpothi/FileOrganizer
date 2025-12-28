//
//  AIClientFactory.swift
//  FileOrganizer
//
//  Factory for creating appropriate AI client
//

import Foundation

struct AIClientFactory {
    static func createClient(config: AIConfig) throws -> AIClientProtocol {
        switch config.provider {
        case .openAICompatible:
            return OpenAIClient(config: config)
            
        case .appleFoundationModel:
            if #available(macOS 15.0, *) {
                if AppleFoundationModelClient.isAvailable() {
                    return AppleFoundationModelClient(config: config)
                } else {
                    throw AIClientError.appleIntelligenceUnavailable
                }
            } else {
                throw AIClientError.appleIntelligenceUnavailable
            }
        }
    }
}

