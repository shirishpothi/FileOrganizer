
import XCTest
@testable import FileOrganizerLib

class FileSystemManagerTests: XCTestCase {
    
    var fileSystemManager: FileSystemManager!
    var tempDirectory: URL!
    
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        fileSystemManager = FileSystemManager()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    @MainActor
    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDirectory)
        fileSystemManager = nil
        try await super.tearDown()
    }
    
    @MainActor
    func testCreateFolders() async throws {
        let plan = OrganizationPlan(
            suggestions: [
                FolderSuggestion(folderName: "Folder1", description: "", files: [], subfolders: [
                    FolderSuggestion(folderName: "Subfolder1", description: "", files: [], subfolders: [], reasoning: "")
                ], reasoning: "")
            ],
            unorganizedFiles: [],
            notes: ""
        )
        
        let ops = try await fileSystemManager.createFolders(plan, at: tempDirectory)
        
        XCTAssertEqual(ops.count, 2)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDirectory.appendingPathComponent("Folder1").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDirectory.appendingPathComponent("Folder1/Subfolder1").path))
    }
    
    @MainActor
    func testMoveFilesWithConflicts() async throws {
        let sourceFile = tempDirectory.appendingPathComponent("test.txt")
        try "Content".write(to: sourceFile, atomically: true, encoding: .utf8)
        
        // Create a conflict at destination
        let destFolder = tempDirectory.appendingPathComponent("Dest")
        try FileManager.default.createDirectory(at: destFolder, withIntermediateDirectories: true)
        let conflictFile = destFolder.appendingPathComponent("test.txt")
        try "Existing Content".write(to: conflictFile, atomically: true, encoding: .utf8)
        
        let fileItem = FileItem(path: sourceFile.path, name: "test", extension: "txt", size: 10, isDirectory: false)
        let plan = OrganizationPlan(
            suggestions: [
                FolderSuggestion(folderName: "Dest", description: "", files: [fileItem], subfolders: [], reasoning: "")
            ],
            unorganizedFiles: [],
            notes: ""
        )
        
        let ops = try await fileSystemManager.moveFiles(plan, at: tempDirectory)
        
        XCTAssertEqual(ops.count, 1)
        // Should have renamed the destination file to test_1.txt
        XCTAssertTrue(FileManager.default.fileExists(atPath: destFolder.appendingPathComponent("test_1.txt").path))
    }
    
    @MainActor
    func testUndoOperations() async throws {
        let file = tempDirectory.appendingPathComponent("to_move.txt")
        try "data".write(to: file, atomically: true, encoding: .utf8)
        
        let fileItem = FileItem(path: file.path, name: "to_move", extension: "txt", size: 4, isDirectory: false)
        let plan = OrganizationPlan(
            suggestions: [
                FolderSuggestion(folderName: "NewDir", description: "", files: [fileItem], subfolders: [], reasoning: "")
            ],
            unorganizedFiles: [],
            notes: ""
        )
        
        let ops = try await fileSystemManager.applyOrganization(plan, at: tempDirectory)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDirectory.appendingPathComponent("NewDir/to_move.txt").path))
        
        try await fileSystemManager.reverseOperations(ops)
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempDirectory.appendingPathComponent("NewDir/to_move.txt").path))
    }
}
