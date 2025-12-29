
import XCTest
@testable import FileOrganizerLib

// Mock AI Client for testing
actor MockAIClient: AIClientProtocol {
    let config: AIConfig
    var analyzeHandler: (([FileItem]) async throws -> OrganizationPlan)?
    
    init(config: AIConfig) {
        self.config = config
    }
    
    func analyze(files: [FileItem], customInstructions: String?, personaPrompt: String?, temperature: Double?) async throws -> OrganizationPlan {
        if let handler = analyzeHandler {
            return try await handler(files)
        }
        return OrganizationPlan(suggestions: [], unorganizedFiles: [], notes: "")
    }
    
    func setHandler(_ handler: @escaping @Sendable ([FileItem]) async throws -> OrganizationPlan) {
        self.analyzeHandler = handler
    }
}

@MainActor
class FileOrganizerTests: XCTestCase {
    
    var folderOrganizer: FolderOrganizer!
    var mockClient: MockAIClient!
    var tempDirectory: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        folderOrganizer = FolderOrganizer()
        let config = AIConfig(apiKey: "test-key", model: "test-model")
        mockClient = MockAIClient(config: config)
        
        // Create a temporary directory for testing
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDown() async throws {
        if let tempDirectory = tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        folderOrganizer = nil
        mockClient = nil
        try await super.tearDown()
    }
    
    func testOrganizeFlow() async throws {
        // 1. Setup: Create a dummy file to scan
        let dummyFileURL = tempDirectory.appendingPathComponent("test.txt")
        try "content".write(to: dummyFileURL, atomically: true, encoding: .utf8)
        
        // 2. Setup: Inject mock client
        folderOrganizer.aiClient = mockClient
        
        // 3. Setup: Define mock behavior
        await mockClient.setHandler { files in
            // Verify we received the file
            XCTAssertEqual(files.count, 1)
            XCTAssertEqual(files.first?.name, "test")
            
            return OrganizationPlan(
                suggestions: [
                    FolderSuggestion(folderName: "Docs", description: "Text", files: files, subfolders: [], reasoning: "Text")
                ],
                unorganizedFiles: [],
                notes: "Test Plan"
            )
        }
        
        // 4. Act
        try await folderOrganizer.organize(directory: tempDirectory)
        
        // 5. Assert
        XCTAssertEqual(folderOrganizer.state, .ready)
        XCTAssertNotNil(folderOrganizer.currentPlan)
        XCTAssertEqual(folderOrganizer.currentPlan?.suggestions.first?.folderName, "Docs")
    }
    
    func testClientNotConfiguredError() async {
        // Ensure client is nil
        folderOrganizer.aiClient = nil
        
        do {
            try await folderOrganizer.organize(directory: tempDirectory)
            XCTFail("Should throw error")
        } catch {
            XCTAssertEqual(error as? OrganizationError, OrganizationError.clientNotConfigured)
        }
    }
}
