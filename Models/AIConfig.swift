//
//  AIConfig.swift
//  FileOrganizer
//
//  AI Configuration Model
//

import Foundation

public enum AIProvider: String, Codable, CaseIterable {
    case openAICompatible = "openai_compatible"
    case appleFoundationModel = "apple_foundation_model"
    
    public var displayName: String {
        switch self {
        case .openAICompatible:
            return "OpenAI-Compatible API"
        case .appleFoundationModel:
            return "Apple Foundation Model"
        }
    }
}

public struct AIConfig: Codable {
    public var provider: AIProvider
    public var apiURL: String?
    public var apiKey: String?
    public var model: String
    public var temperature: Double
    
    public init(
        provider: AIProvider = .openAICompatible,
        apiURL: String? = nil,
        apiKey: String? = nil,
        model: String = "gpt-4",
        temperature: Double = 0.7
    ) {
        self.provider = provider
        self.apiURL = apiURL
        self.apiKey = apiKey
        self.model = model
        self.temperature = temperature
    }
    
    public static let `default` = AIConfig(
        provider: .openAICompatible,
        apiURL: "https://api.openai.com",
        model: "gpt-4",
        temperature: 0.7
    )
}

