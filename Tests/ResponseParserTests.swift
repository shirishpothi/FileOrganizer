
import XCTest
@testable import FileOrganizerLib

class ResponseParserTests: XCTestCase {
    
    func testValidJSONParsing() throws {
        let json = """
        {
          "folders": [
            {
              "name": "Images",
              "description": "Photo files",
              "reasoning": "Detected image extensions",
              "files": ["vacation.jpg", "profile.png"]
            }
          ],
          "notes": "Organized by file type"
        }
        """
        
        let files = [
            FileItem(path: "/path/vacation.jpg", name: "vacation", extension: "jpg", size: 100, isDirectory: false),
            FileItem(path: "/path/profile.png", name: "profile", extension: "png", size: 200, isDirectory: false),
            FileItem(path: "/path/notes.txt", name: "notes", extension: "txt", size: 50, isDirectory: false)
        ]
        
        let plan = try ResponseParser.parseResponse(json, originalFiles: files)
        
        XCTAssertEqual(plan.suggestions.count, 1)
        XCTAssertEqual(plan.suggestions.first?.folderName, "Images")
        XCTAssertEqual(plan.suggestions.first?.files.count, 2)
        XCTAssertEqual(plan.notes, "Organized by file type")
    }
    
    func testMarkdownWrappedJSONParsing() throws {
        let json = """
        ```json
        {
          "folders": [
            {
              "name": "Docs",
              "files": ["report.pdf"]
            }
          ]
        }
        ```
        """
        
        let files = [FileItem(path: "/path/report.pdf", name: "report", extension: "pdf", size: 100, isDirectory: false)]
        
        let plan = try ResponseParser.parseResponse(json, originalFiles: files)
        
        XCTAssertEqual(plan.suggestions.count, 1)
        XCTAssertEqual(plan.suggestions.first?.folderName, "Docs")
    }
    
    func testUnorganizedFilesParsing() throws {
        let json = """
        {
          "folders": [],
          "unorganized": [
            {
              "filename": "unknown.xyz",
              "reason": "Unknown file type"
            }
          ]
        }
        """
        
        let files = [FileItem(path: "/path/unknown.xyz", name: "unknown", extension: "xyz", size: 100, isDirectory: false)]
        
        let plan = try ResponseParser.parseResponse(json, originalFiles: files)
        
        XCTAssertEqual(plan.unorganizedDetails.count, 1)
        XCTAssertEqual(plan.unorganizedDetails.first?.filename, "unknown.xyz")
        XCTAssertEqual(plan.unorganizedFiles.count, 1)
    }

    func testParsingWithTags() throws {
        let json = """
        {
          "folders": [
            {
              "name": "TaggedDocs",
              "files": [
                {
                  "filename": "invoice.pdf",
                  "tags": ["Finance", "2024"]
                }
              ]
            }
          ]
        }
        """
        
        let files = [
            FileItem(path: "/path/invoice.pdf", name: "invoice", extension: "pdf", size: 100, isDirectory: false)
        ]
        
        let plan = try ResponseParser.parseResponse(json, originalFiles: files)
        
        XCTAssertEqual(plan.suggestions.count, 1)
        let suggestion = plan.suggestions.first!
        XCTAssertEqual(suggestion.folderName, "TaggedDocs")
        
        // Check tags
        let tags = suggestion.tags(for: files[0])
        XCTAssertEqual(tags.count, 2)
        XCTAssertTrue(tags.contains("Finance"))
        XCTAssertTrue(tags.contains("2024"))
    }
}
