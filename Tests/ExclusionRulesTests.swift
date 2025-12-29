
import XCTest
@testable import FileOrganizerLib

@MainActor
class ExclusionRulesTests: XCTestCase {
    
    var manager: ExclusionRulesManager!
    
    override func setUp() async throws {
        try await super.setUp()
        manager = ExclusionRulesManager()
        // Clear existing rules to start fresh
        for rule in manager.rules {
            manager.removeRule(rule)
        }
    }
    
    func testExtensionExclusion() {
        let rule = ExclusionRule(type: .fileExtension, pattern: "tmp")
        manager.addRule(rule)
        
        let file1 = FileItem(path: "/p/a.tmp", name: "a", extension: "tmp", size: 0, isDirectory: false)
        let file2 = FileItem(path: "/p/b.txt", name: "b", extension: "txt", size: 0, isDirectory: false)
        
        XCTAssertTrue(manager.shouldExclude(file1))
        XCTAssertFalse(manager.shouldExclude(file2))
    }
    
    func testFileNameExclusion() {
        let rule = ExclusionRule(type: .fileName, pattern: "secret")
        manager.addRule(rule)
        
        let file1 = FileItem(path: "/p/my_secret_file.txt", name: "my_secret_file", extension: "txt", size: 0, isDirectory: false)
        let file2 = FileItem(path: "/p/normal.txt", name: "normal", extension: "txt", size: 0, isDirectory: false)
        
        XCTAssertTrue(manager.shouldExclude(file1))
        XCTAssertFalse(manager.shouldExclude(file2))
    }
    
    func testFolderNameExclusion() {
        let rule = ExclusionRule(type: .folderName, pattern: "cache")
        manager.addRule(rule)
        
        let file1 = FileItem(path: "/Library/Cache/data.db", name: "data", extension: "db", size: 0, isDirectory: false)
        let file2 = FileItem(path: "/Documents/data.db", name: "data", extension: "db", size: 0, isDirectory: false)
        
        XCTAssertTrue(manager.shouldExclude(file1))
        XCTAssertFalse(manager.shouldExclude(file2))
    }
    
    func testDisabledRule() {
        let rule = ExclusionRule(type: .fileExtension, pattern: "tmp", isEnabled: false)
        manager.addRule(rule)
        
        let file = FileItem(path: "/p/a.tmp", name: "a", extension: "tmp", size: 0, isDirectory: false)
        XCTAssertFalse(manager.shouldExclude(file))
    }
}
