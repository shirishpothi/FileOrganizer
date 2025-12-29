//
//  ExclusionRulesView.swift
//  FileOrganizer
//
//  Exclusion rules management with improved UI
//

import SwiftUI

struct ExclusionRulesView: View {
    @StateObject private var rulesManager = ExclusionRulesManager()
    @State private var showingAddRule = false
    
    var body: some View {
        VStack(spacing: 0) {
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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddRule = true
                } label: {
                    Label("Add Rule", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }
        }
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
                Text(rule.pattern)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(rule.isEnabled ? .primary : .secondary)
                
                HStack(spacing: 8) {
                    Text(rule.type.rawValue.capitalized)
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
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
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
        }
    }
}

struct AddExclusionRuleView: View {
    @ObservedObject var rulesManager: ExclusionRulesManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedType: ExclusionRuleType = .fileExtension
    @State private var pattern: String = ""
    @State private var description: String = ""
    
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
                .disabled(pattern.isEmpty)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            // Form
            Form {
                Picker("Type", selection: $selectedType) {
                    ForEach([ExclusionRuleType.fileExtension, .fileName, .folderName, .pathContains], id: \.self) { type in
                        Label(labelForType(type), systemImage: iconForType(type))
                            .tag(type)
                    }
                }
                .pickerStyle(.menu)
                
                TextField("Pattern", text: $pattern)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Description (optional)", text: $description)
                    .textFieldStyle(.roundedBorder)
                
                Section {
                    Text(helpTextForType(selectedType))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .padding()
        }
        .frame(width: 450, height: 350)
    }
    
    private func addRule() {
        let rule = ExclusionRule(
            type: selectedType,
            pattern: pattern,
            description: description.isEmpty ? nil : description
        )
        rulesManager.addRule(rule)
        dismiss()
    }
    
    private func labelForType(_ type: ExclusionRuleType) -> String {
        switch type {
        case .fileExtension: return "File Extension"
        case .fileName: return "File Name"
        case .folderName: return "Folder Name"
        case .pathContains: return "Path Contains"
        }
    }
    
    private func iconForType(_ type: ExclusionRuleType) -> String {
        switch type {
        case .fileExtension: return "doc.badge.gearshape"
        case .fileName: return "doc"
        case .folderName: return "folder"
        case .pathContains: return "arrow.triangle.branch"
        }
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
        }
    }
}

