//
//  ExclusionRulesView.swift
//  FileOrganizer
//
//  Exclusion rules management with improved UI
//  Updated to handle all rule types including new semantic types
//

import SwiftUI

struct ExclusionRulesView: View {
    @EnvironmentObject var rulesManager: ExclusionRulesManager
    @State private var showingAddRule = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Exclusion Rules")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("\(rulesManager.enabledRulesCount) rules active")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    showingAddRule = true
                } label: {
                    Label("Add Rule", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            if rulesManager.rules.isEmpty {
                // Empty state
                VStack(spacing: 20) {
                    Image(systemName: "eye.slash.circle")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)

                    VStack(spacing: 8) {
                        Text("No Exclusion Rules")
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text("Add rules to exclude certain files or folders from organization")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 300)
                    }

                    Button {
                        showingAddRule = true
                    } label: {
                        Label("Add Rule", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxHeight: .infinity)
            } else {
                // Rules list
                List {
                    ForEach(rulesManager.rules) { rule in
                        ExclusionRuleRow(rule: rule, rulesManager: rulesManager)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            rulesManager.removeRule(rulesManager.rules[index])
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("Exclusion Rules")
        .sheet(isPresented: $showingAddRule) {
            AddExclusionRuleView(rulesManager: rulesManager)
        }
    }
}

struct ExclusionRuleRow: View {
    let rule: ExclusionRule
    @ObservedObject var rulesManager: ExclusionRulesManager

    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: Binding(
                get: { rule.isEnabled },
                set: { newValue in
                    var updatedRule = rule
                    updatedRule.isEnabled = newValue
                    rulesManager.updateRule(updatedRule)
                }
            ))
            .toggleStyle(.switch)
            .labelsHidden()

            Image(systemName: iconForType(rule.type))
                .foregroundStyle(rule.isEnabled ? .primary : .secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(rule.displayDescription)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(rule.isEnabled ? .primary : .secondary)

                HStack(spacing: 8) {
                    Text(rule.type.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.secondary.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    if let description = rule.description {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if rule.isBuiltIn {
                        Text("Built-in")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .opacity(rule.isEnabled ? 1.0 : 0.6)
    }

    private func iconForType(_ type: ExclusionRuleType) -> String {
        switch type {
        case .fileExtension:
            return "doc.badge.gearshape"
        case .fileName:
            return "doc"
        case .folderName:
            return "folder"
        case .pathContains:
            return "arrow.triangle.branch"
        case .regex:
            return "text.magnifyingglass"
        case .fileSize:
            return "scalemass.fill"
        case .creationDate:
            return "calendar.badge.clock"
        case .modificationDate:
            return "calendar.badge.clock"
        case .hiddenFiles:
            return "eye.slash"
        case .systemFiles:
            return "gearshape.2"
        case .fileType:
            return "doc.on.doc"
        case .customScript:
            return "applescript"
        }
    }
}

struct AddExclusionRuleView: View {
    @ObservedObject var rulesManager: ExclusionRulesManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedType: ExclusionRuleType = .fileExtension
    @State private var pattern: String = ""
    @State private var description: String = ""
    @State private var numericValue: Double = 100
    @State private var comparisonGreater: Bool = true
    @State private var selectedFileTypeCategory: FileTypeCategory = .images

    // Test section state
    @State private var testInput: String = ""
    @State private var isMatch: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])

                Spacer()

                Text("Add Exclusion Rule")
                    .font(.headline)

                Spacer()

                Button("Add") {
                    addRule()
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(!isValidInput)
                .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

            // Form
            Form {
                Picker("Type", selection: $selectedType) {
                    ForEach(ExclusionRuleType.allCases) { type in
                        Label(type.rawValue, systemImage: type.icon)
                            .tag(type)
                    }

                }
                .pickerStyle(.menu)

                // Type-specific inputs
                Group {
                    switch selectedType {
                    case .fileSize:
                        HStack {
                            TextField("Size", value: $numericValue, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                            Text("MB")

                            Picker("", selection: $comparisonGreater) {
                                Text("Larger than").tag(true)
                                Text("Smaller than").tag(false)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 200)
                        }

                    case .creationDate, .modificationDate:
                        HStack {
                            TextField("Days", value: $numericValue, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                            Text("days ago")

                            Picker("", selection: $comparisonGreater) {
                                Text("Older than").tag(true)
                                Text("Newer than").tag(false)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 200)
                        }

                    case .fileType:
                        Picker("Category", selection: $selectedFileTypeCategory) {
                            ForEach(FileTypeCategory.allCases) { category in
                                Label(category.rawValue, systemImage: category.icon)
                                    .tag(category)
                            }
                        }
                        .pickerStyle(.menu)

                        Text("Includes: \(selectedFileTypeCategory.extensions.prefix(5).joined(separator: ", "))\(selectedFileTypeCategory.extensions.count > 5 ? "..." : "")")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                    case .hiddenFiles, .systemFiles:
                        Text("This rule type does not require a pattern.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                    case .customScript:
                        Text("Custom scripts are not yet implemented.")
                            .font(.caption)
                            .foregroundStyle(.orange)

                    case .fileExtension, .fileName, .folderName, .pathContains, .regex:
                        TextField("Pattern", text: $pattern)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                TextField("Description (optional)", text: $description)
                    .textFieldStyle(.roundedBorder)

                Section {
                    Text(helpTextForType(selectedType))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if selectedType.requiresPattern && selectedType != .fileType {
                    Section("Test Rule") {
                        VStack(alignment: .leading, spacing: 8) {
                            TextField(testPlaceholder, text: $testInput)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: testInput) { _, _ in checkMatch() }
                                .onChange(of: pattern) { _, _ in checkMatch() }
                                .onChange(of: selectedType) { _, _ in checkMatch() }

                            if !testInput.isEmpty {
                                HStack {
                                    Image(systemName: isMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(isMatch ? .green : .red)
                                    Text(isMatch ? "Matches rule" : "Does not match")
                                        .font(.caption)
                                        .foregroundColor(isMatch ? .green : .secondary)
                                }
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .padding()
        }
        .frame(width: 550, height: 500)
    }

    private var isValidInput: Bool {
        switch selectedType {
        case .hiddenFiles, .systemFiles:
            return true
        case .fileType:
            return true
        case .fileSize, .creationDate, .modificationDate:
            return numericValue > 0
        case .customScript:
            return false // Not implemented
        default:
            return !pattern.isEmpty
        }
    }

    private func checkMatch() {
        guard !testInput.isEmpty, !pattern.isEmpty else {
            isMatch = false
            return
        }

        // Create a mock file item to test against
        let fileName = testInput.contains(".") ? String(testInput.split(separator: ".").dropLast().joined(separator: ".")) : testInput
        let fileExtension = testInput.contains(".") ? String(testInput.split(separator: ".").last ?? "") : ""

        let file = FileItem(
            path: "/path/to/\(testInput)",
            name: fileName,
            extension: fileExtension,
            size: Int64((Double(testInput) ?? 0) * 1024 * 1024),
            isDirectory: false,
            creationDate: Date()
        )

        let rule = ExclusionRule(
            type: selectedType,
            pattern: pattern,
            numericValue: numericValue,
            comparisonGreater: comparisonGreater
        )

        isMatch = rule.matches(file)
    }

    private var testPlaceholder: String {
        switch selectedType {
        case .fileExtension:
            return "Enter filename (e.g. document.txt)"
        case .fileName:
            return "Enter filename"
        case .folderName:
            return "Enter folder path or name"
        case .pathContains:
            return "Enter full path"
        case .regex:
            return "Enter text to match"
        case .fileSize:
            return "Enter size in MB (e.g. 10.5)"
        case .creationDate, .modificationDate:
            return "Test not available for date"
        case .hiddenFiles, .systemFiles:
            return "No test needed"
        case .fileType:
            return "No test needed"
        case .customScript:
            return "Not implemented"
        }
    }

    private func addRule() {
        var rule = ExclusionRule(
            type: selectedType,
            pattern: pattern,
            description: description.isEmpty ? nil : description
        )

        // Set type-specific properties
        switch selectedType {
        case .fileSize, .creationDate, .modificationDate:
            rule = ExclusionRule(
                type: selectedType,
                pattern: pattern,
                description: description.isEmpty ? nil : description,
                numericValue: numericValue,
                comparisonGreater: comparisonGreater
            )
        case .fileType:
            rule = ExclusionRule(
                type: selectedType,
                pattern: "",
                description: description.isEmpty ? nil : description,
                fileTypeCategory: selectedFileTypeCategory
            )
        default:
            break
        }

        rulesManager.addRule(rule)
        dismiss()
    }

    private func helpTextForType(_ type: ExclusionRuleType) -> String {
        switch type {
        case .fileExtension:
            return "Example: 'txt' will exclude all .txt files"
        case .fileName:
            return "Example: '.DS_Store' will exclude all .DS_Store files"
        case .folderName:
            return "Example: 'node_modules' will exclude all node_modules folders"
        case .pathContains:
            return "Example: '/backup/' will exclude any path containing '/backup/'"
        case .regex:
            return "Example: '^IMG_\\d{4}$' excludes matches (Advanced)"
        case .fileSize:
            return "Excludes files larger/smaller than specified size in MB"
        case .creationDate:
            return "Excludes files created older/newer than specified days"
        case .modificationDate:
            return "Excludes files modified older/newer than specified days"
        case .hiddenFiles:
            return "Excludes files starting with '.' (hidden files)"
        case .systemFiles:
            return "Excludes macOS system files like .DS_Store, Thumbs.db, etc."
        case .fileType:
            return "Excludes entire categories of files by type"
        case .customScript:
            return "Run custom AppleScript to determine exclusion (advanced)"
        }
    }
}

#Preview {
    ExclusionRulesView()
        .environmentObject(ExclusionRulesManager())
        .frame(width: 600, height: 500)
}
