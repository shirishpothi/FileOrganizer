// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "FileOrganizer",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "FileOrganizerLib",
            targets: ["FileOrganizerLib"]),
        .executable(
            name: "FileOrganizerApp",
            targets: ["FileOrganizerApp"])
    ],
    targets: [
        // Target for the core logic (Models, AI, Organizer, etc.)
        .target(
            name: "FileOrganizerLib",
            path: ".",
            exclude: [
                "FileOrganizerApp.swift",
                "Tests",
                "FinderExtension/FileOrganizerActionExtension.swift",
                "FileOrganizer.app",
                "build.sh",
                "Makefile",
                "README.md",
                "QUICK_START.md",
                "SETUP.md"
            ],
            sources: [
                "AI",
                "FileSystem",
                "Models",
                "Organizer",
                "Utilities",
                "ViewModels",
                "Views",
                "FinderExtension"
            ]
        ),
        // Target for the App (contains Views and App entry)
        .executableTarget(
            name: "FileOrganizerApp",
            dependencies: ["FileOrganizerLib"],
            path: ".",
            exclude: [
                "Tests",
                "FinderExtension",
                "AI", "FileSystem", "Models", "Organizer", "Utilities", "ViewModels", "Views",
                "FileOrganizer.app",
                "build.sh",
                "Makefile",
                "README.md",
                "QUICK_START.md",
                "SETUP.md"
            ],
            sources: [
                "FileOrganizerApp.swift",
                "AppCoordinator.swift"
            ]
        ),
        .testTarget(
            name: "FileOrganizerTests",
            dependencies: ["FileOrganizerLib"],
            path: "Tests"
        )
    ]
)

