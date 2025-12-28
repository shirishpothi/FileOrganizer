
import XCTest
@testable import FileOrganizerLib

// Mock AI Client for testing
class MockAIClient: AIClientProtocol {
    var config: AIConfig
    var analyzeHandler: (([FileItem]) async throws -> OrganizationPlan)?
    
    init(config: AIConfig) {
        self.config = config
    }
    
    func analyze(files: [FileItem]) async throws -> OrganizationPlan {
        if let handler = analyzeHandler {
            return try await handler(files)
        }
        return OrganizationPlan(suggestions: [], unorganizedFiles: [], notes: "")
    }
}

@MainActor
class FileOrganizerTests: XCTestCase {
    
    var folderOrganizer: FolderOrganizer!
    var mockClient: MockAIClient!
    var tempDirectory: URL!
    
    override func setUp() {
        super.setUp()
        folderOrganizer = FolderOrganizer()
        let config = AIConfig(apiKey: "test-key", model: "test-model")
        mockClient = MockAIClient(config: config)
        
        // Create a temporary directory for testing
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDown() {
        if let tempDirectory = tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        folderOrganizer = nil
        mockClient = nil
        super.tearDown()
    }
    
    func testOrganizeFlow() async throws {
        // 1. Setup: Create a dummy file to scan
        let dummyFileURL = tempDirectory.appendingPathComponent("test.txt")
        try "content".write(to: dummyFileURL, atomically: true, encoding: .utf8)
        
        // 2. Setup: Inject mock client
        folderOrganizer.aiClient = mockClient
        
        // 3. Setup: Define mock behavior
        mockClient.analyzeHandler = { files in
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
