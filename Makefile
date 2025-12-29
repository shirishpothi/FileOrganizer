# FileOrganizer Makefile

.PHONY: build run test clean help

# Default target
all: build

build:
	@chmod +x build.sh
	@./build.sh

run: build
	@echo "🚀 Launching FileOrganizer..."
	@open FileOrganizer.app

test:
	@echo "🧪 Running Swift tests..."
	@swift test

clean:
	@echo "🧹 Cleaning build artifacts..."
	@swift package clean
	@rm -rf .build
	@rm -rf FileOrganizer.app/Contents/MacOS/FileOrganizerApp
	@echo "✨ Clean complete"

help:
	@echo "Available commands:"
	@echo "  make build - Compile and update the .app bundle"
	@echo "  make run   - Build and launch the app"
	@echo "  make test  - Run all Swift tests"
	@echo "  make clean - Remove build artifacts"
