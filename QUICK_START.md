# Quick Start Guide - Running File Organizer

## Prerequisites

1. **Xcode 15.0 or later** (download from Mac App Store)
2. **macOS 13.0 or later**
3. **Apple Developer Account** (free account works for development)

## Step-by-Step Setup

### 1. Create Xcode Project

1. Open **Xcode**
2. Select **File → New → Project**
3. Choose **macOS** tab
4. Select **App** template
5. Click **Next**
6. Configure:
   - **Product Name**: `FileOrganizer`
   - **Team**: Select your team (or "None" for personal use)
   - **Organization Identifier**: `com.yourname` (or your domain)
   - **Bundle Identifier**: Will auto-generate as `com.yourname.FileOrganizer`
   - **Interface**: **SwiftUI**
   - **Language**: **Swift**
   - **Storage**: **None** (we'll add our own)
   - **Minimum Deployment**: **macOS 13.0**
7. Click **Next**
8. **Save location**: Navigate to `/Users/shirishpothi/Downloads/File Organiser/` and click **Create**
9. **Important**: When prompted "The folder already contains items", choose **"Create"** (don't replace)

### 2. Add Source Files to Project

1. In Xcode, right-click on the **FileOrganizer** folder in the Project Navigator
2. Select **Add Files to "FileOrganizer"...**
3. Navigate to the `FileOrganizer` subdirectory
4. Select **ALL** the subdirectories:
   - `AI/`
   - `FileSystem/`
   - `FinderExtension/`
   - `Models/`
   - `Organizer/`
   - `Utilities/`
   - `ViewModels/`
   - `Views/`
5. **Important Options**:
   - ✅ Check **"Copy items if needed"** (if files aren't already in the project)
   - ✅ Check **"Create groups"** (not folder references)
   - ✅ Select **"FileOrganizer"** target
6. Click **Add**

### 3. Replace Default App File

1. Delete the default `ContentView.swift` and `FileOrganizerApp.swift` that Xcode created (if they exist)
2. Our `FileOrganizerApp.swift` should now be in the project

### 4. Configure App Groups (Required for Finder Extension)

1. Select the **FileOrganizer** target in Project Navigator
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Groups**
5. Click **+** next to App Groups
6. Enter: `group.com.fileorganizer.app`
7. ✅ Check the box to enable it

### 5. Create Finder Extension Target

1. **File → New → Target**
2. Select **macOS** tab
3. Choose **Finder Extension**
4. Click **Next**
5. Configure:
   - **Product Name**: `FileOrganizerExtension`
   - **Bundle Identifier**: Will auto-generate
6. Click **Finish**
7. When prompted, click **Activate** for the scheme

### 6. Add Extension Files to Extension Target

1. Select `FileOrganizerActionExtension.swift` in Project Navigator
2. In File Inspector (right panel), under **Target Membership**
3. ✅ Check **FileOrganizerExtension**
4. Repeat for `ExtensionCommunication.swift`

### 7. Configure Extension App Groups

1. Select **FileOrganizerExtension** target
2. Go to **Signing & Capabilities**
3. Add **App Groups** capability
4. Select the same group: `group.com.fileorganizer.app`

### 8. Update Extension Info.plist

1. Open `FileOrganizerExtension/Info.plist`
2. Ensure it contains:
```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.finder-sync</string>
</dict>
```

### 9. Build and Run

1. Select **FileOrganizer** scheme (not the extension) from the scheme selector
2. Select your Mac as the destination
3. Press **⌘R** (or click the Play button)
4. The app should launch!

## First Run

1. **Configure AI Settings**:
   - Go to **Settings** tab
   - Choose your AI provider:
     - **OpenAI-Compatible**: Enter API URL and key
     - **Apple Foundation Model**: Requires macOS 15.0+ with Apple Intelligence
   - Click **Test Connection** to verify

2. **Organize a Folder**:
   - Go to **Organize** tab
   - Click **Browse for Folder** or drag-drop a folder
   - Click **Start Organization**
   - Review the preview
   - Click **Apply Organization** when satisfied

## Troubleshooting

### Build Errors

- **"Cannot find type 'X' in scope"**: Make sure all files are added to the target
- **"No such module 'FoundationModels'"**: This is expected - the framework may not be available yet. The code will fall back gracefully.

### Finder Extension Not Appearing

1. Build and run the **FileOrganizerExtension** target once
2. Go to **System Settings → Privacy & Security → Extensions → Finder Extensions**
3. Enable **FileOrganizerExtension**
4. Restart Finder: `killall Finder` in Terminal

### App Crashes on Launch

- Check Console.app for error messages
- Ensure all required files are in the project
- Verify App Groups are configured correctly

## Testing Without Finder Extension

You can test the main app functionality without setting up the Finder extension:
1. Just skip steps 5-8
2. The app will work for manual folder selection
3. The Finder extension is optional

## Next Steps

- Configure your AI API credentials
- Test with a small test folder first
- Review the organization preview before applying
- Check the History tab to see past operations

