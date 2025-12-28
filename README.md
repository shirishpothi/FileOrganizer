# File Organizer - macOS App

A native macOS SwiftUI application that uses AI to intelligently organize directory contents into relevant folders.

## Features

- **Multiple AI Providers**: 
  - OpenAI-compatible APIs (OpenAI, Anthropic, GitHub Copilot, etc.)
  - Apple Foundation Models (on-device, privacy-focused) - [Documentation](https://developer.apple.com/documentation/foundationmodels)
- **Finder Extension**: Right-click any folder in Finder to organize it
- **Preview System**: Preview organization suggestions before applying, with ability to regenerate
- **Safe Operations**: Dry-run mode, undo support, and comprehensive validation
- **Organization History**: Track all operations with statistics and analytics
- **Exclusion Rules**: Configure rules to exclude specific files or folders
- **Modern UI**: Clean SwiftUI interface with dark mode support

## Requirements

- macOS 13.0 or later
- Xcode 15.0 or later
- Swift 5.9+

## Setup

1. Open the project in Xcode
2. Configure your AI provider in Settings:
   - For OpenAI-compatible: Enter API URL and key
   - For Apple Foundation Models: Requires macOS 15+ with Apple Intelligence
3. Select a directory to organize or use the Finder extension

## Project Structure

```
FileOrganizer/
├── FileOrganizerApp.swift          # Main app entry point
├── Models/                         # Data models
├── AI/                            # AI client implementations
├── FileSystem/                    # Directory scanning and file operations
├── Organizer/                     # Business logic
├── Views/                         # SwiftUI views
├── ViewModels/                    # View models
├── FinderExtension/               # Finder extension
└── Utilities/                     # Helper utilities
```

## Configuration

### App Groups
The Finder extension requires App Groups to be configured:
- App Group ID: `group.com.fileorganizer.app`
- Configure this in both the main app and extension targets

### Entitlements
- Main app: App Groups entitlement
- Extension: App Groups and Finder Sync entitlements

## Usage

1. **From App**: Open the app, select a directory, and click "Start Organization"
2. **From Finder**: Right-click a folder → "Organize with AI..."
3. **Preview**: Review the suggested organization
4. **Regenerate**: Click "Try Different Organization" for a new suggestion
5. **Apply**: Click "Apply Organization" to execute

## License

MIT License

