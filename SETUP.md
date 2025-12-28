# File Organizer - Setup Guide

## Xcode Project Setup

### 1. Create New Project
1. Open Xcode
2. Create a new macOS App project
3. Name it "FileOrganizer"
4. Choose SwiftUI as the interface
5. Set minimum deployment to macOS 13.0

### 2. Add Files to Project
Add all files from the `FileOrganizer/` directory to your Xcode project, maintaining the folder structure:
- Models/
- AI/
- FileSystem/
- Organizer/
- Views/
- ViewModels/
- FinderExtension/
- Utilities/

### 3. Configure App Groups
1. Select the main app target
2. Go to "Signing & Capabilities"
3. Click "+ Capability"
4. Add "App Groups"
5. Create/select group: `group.com.fileorganizer.app`

### 4. Create Finder Extension Target
1. File → New → Target
2. Choose "Finder Extension" template
3. Name it "FileOrganizerExtension"
4. Add the FinderExtension files to this target:
   - `FileOrganizerActionExtension.swift`
   - `ExtensionCommunication.swift`
5. Configure App Groups for the extension:
   - Same App Group: `group.com.fileorganizer.app`

### 5. Configure Extension Info.plist
In the extension's Info.plist, add:
```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.finder-sync</string>
</dict>
```

### 6. Bundle Identifier
- Main app: `com.fileorganizer.app`
- Extension: `com.fileorganizer.app.extension`

### 7. Required Frameworks
Ensure these are linked:
- Foundation
- SwiftUI
- Combine
- FinderSync (for extension)

### 8. Build Settings
- Swift Language Version: Swift 5.9
- Deployment Target: macOS 13.0
- For Apple Foundation Models support: macOS 15.0+ (requires Apple Intelligence)

### 9. Add Foundation Models Framework (Optional)
If using Apple Foundation Models:
1. In Xcode, select your target
2. Go to "General" → "Frameworks, Libraries, and Embedded Content"
3. Click "+" and add "FoundationModels.framework"
4. Ensure it's set to "Do Not Embed"
5. Update `AppleFoundationModelClient.swift` with actual API calls from the [documentation](https://developer.apple.com/documentation/foundationmodels)

## Testing

### Test Main App
1. Run the app
2. Configure AI settings
3. Select a test directory
4. Verify organization workflow

### Test Finder Extension
1. Build and run the extension target
2. Right-click a folder in Finder
3. Verify "Organize with AI..." appears in context menu
4. Click it and verify main app opens with directory selected

## Known Limitations

1. **Apple Foundation Models**: The implementation structure is in place using the [Foundation Models framework](https://developer.apple.com/documentation/foundationmodels). The actual API calls are commented with pseudo-code. When you have access to the framework:
   - Uncomment and implement the actual API calls in `AppleFoundationModelClient.swift`
   - The framework supports guided generation (for JSON output), tool calling, and stateful sessions
   - Requires macOS 15.0+ and Apple Intelligence-enabled devices

2. **Finder Extension**: Requires proper code signing and App Groups configuration. The extension may need to be enabled in System Preferences → Extensions.

3. **Large Directories**: The app warns about operations with 1000+ files. Consider implementing pagination or chunking for very large directories.

## Next Steps

1. Add proper error handling for network failures
2. Implement undo functionality UI
3. Add batch processing UI
4. Create organization templates feature
5. Add export/import for exclusion rules
6. Implement smart suggestions based on history

