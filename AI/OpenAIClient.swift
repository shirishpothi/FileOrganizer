//
//  OpenAIClient.swift
//  FileOrganizer
//
//  OpenAI-Compatible API Client
//

import Foundation

class OpenAIClient: AIClientProtocol {
    let config: AIConfig
    private let session: URLSession
    
    init(config: AIConfig) {
        self.config = config
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 60
        sessionConfig.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: sessionConfig)
    }
    
    func analyze(files: [FileItem]) async throws -> OrganizationPlan {
        guard let apiURL = config.apiURL else {
            throw AIClientError.missingAPIURL
        }
        
        guard let apiKey = config.apiKey else {
            throw AIClientError.missingAPIKey
        }
        
        let endpoint = "\(apiURL)/v1/chat/completions"
        guard let url = URL(string: endpoint) else {
            throw AIClientError.invalidURL
        }
        
        let systemPrompt = PromptBuilder.buildSystemPrompt()
        let userPrompt = PromptBuilder.buildAnalysisPrompt(files: files)
        
        let requestBody: [String: Any] = [
            "model": config.model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "temperature": config.temperature,
            "response_format": ["type": "json_object"]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIClientError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw AIClientError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
            
            let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let choices = jsonResponse?["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                throw AIClientError.invalidResponseFormat
            }
            
            return try ResponseParser.parseResponse(content, originalFiles: files)
        } catch let error as AIClientError {
            throw error
        } catch {
            throw AIClientError.networkError(error)
        }
    }
}

enum AIClientError: LocalizedError {
    case missingAPIURL
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case invalidResponseFormat
    case apiError(statusCode: Int, message: String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIURL:
            return "API URL is required"
        case .missingAPIKey:
            return "API key is required"
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from API"
        case .invalidResponseFormat:
            return "Response format is invalid"
        case .apiError(let statusCode, let message):
            return "API error (\(statusCode)): \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

