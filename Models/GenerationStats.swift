//
//  GenerationStats.swift
//  FileOrganizer
//
//  Created by Antigravity on 12/31/25.
//

import Foundation

public struct GenerationStats: Codable, Sendable, Hashable {
    public let duration: TimeInterval
    public let tps: Double
    public let ttft: TimeInterval
    public let totalTokens: Int
    public let model: String
    
    public init(duration: TimeInterval, tps: Double, ttft: TimeInterval, totalTokens: Int, model: String) {
        self.duration = duration
        self.tps = tps
        self.ttft = ttft
        self.totalTokens = totalTokens
        self.model = model
    }
}
