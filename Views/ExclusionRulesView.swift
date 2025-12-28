//
//  ExclusionRulesView.swift
//  FileOrganizer
//
//  Exclusion rules management view
//

import SwiftUI

struct ExclusionRulesView: View {
    @StateObject private var rulesManager = ExclusionRulesManager()
    @State private var showingAddRule = false
    
    var body: some View {
        NavigationView {
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
            .navigationTitle("Exclusion Rules")
            .toolbar {
                Button(action: { showingAddRule = true }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAddRule) {
                AddExclusionRuleView(rulesManager: rulesManager)
            }
        }
    }
}

struct ExclusionRuleRow: View {
    let rule: ExclusionRule
    @ObservedObject var rulesManager: ExclusionRulesManager
    
    var body: some View {
        HStack {
            Toggle("", isOn: Binding(
                get: { rule.isEnabled },
                set: { newValue in
                    var updatedRule = rule
                    updatedRule.isEnabled = newValue
                    rulesManager.updateRule(updatedRule)
                }
            ))
            
            VStack(alignment: .leading) {
                Text(rule.type.rawValue.capitalized)
                    .font(.headline)
                Text(rule.pattern)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let description = rule.description {
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
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
        NavigationView {
            Form {
                Picker("Type", selection: $selectedType) {
                    ForEach([ExclusionRuleType.fileExtension, .fileName, .folderName, .pathContains], id: \.self) { type in
                        Text(type.rawValue.capitalized).tag(type)
                    }
                }
                
                TextField("Pattern", text: $pattern)
                TextField("Description (optional)", text: $description)
            }
            .navigationTitle("Add Exclusion Rule")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let rule = ExclusionRule(
                            type: selectedType,
                            pattern: pattern,
                            description: description.isEmpty ? nil : description
                        )
                        rulesManager.addRule(rule)
                        dismiss()
                    }
                    .disabled(pattern.isEmpty)
                }
            }
        }
        .frame(width: 400, height: 300)
    }
}

