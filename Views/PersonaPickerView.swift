//
//  PersonaPickerView.swift
//  FileOrganizer
//
//  UI for selecting organization personas
//

import SwiftUI

struct PersonaPickerView: View {
    @EnvironmentObject var personaManager: PersonaManager
    @State private var hoveringPersona: PersonaType?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Organization Style")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                ForEach(PersonaType.allCases, id: \.self) { persona in
                    PersonaButton(
                        persona: persona,
                        isSelected: personaManager.selectedPersona == persona,
                        isHovering: hoveringPersona == persona
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            personaManager.selectPersona(persona)
                        }
                    }
                    .onHover { hovering in
                        hoveringPersona = hovering ? persona : nil
                    }
                }
            }
            
            // Description of selected persona
            Text(personaManager.selectedPersona.description)
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.easeInOut, value: personaManager.selectedPersona)
        }
    }
}

struct PersonaButton: View {
    let persona: PersonaType
    let isSelected: Bool
    let isHovering: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: persona.icon)
                    .font(.system(size: 18))
                    .symbolRenderingMode(.hierarchical)
                
                Text(persona.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(
                                isSelected ? Color.accentColor : Color.secondary.opacity(isHovering ? 0.5 : 0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .foregroundColor(isSelected ? .accentColor : .primary)
            .scaleEffect(isHovering && !isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(persona.displayName) organization style")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Compact inline picker for the ready-to-organize screen
struct CompactPersonaPicker: View {
    @EnvironmentObject var personaManager: PersonaManager
    
    var body: some View {
        Menu {
            ForEach(PersonaType.allCases, id: \.self) { persona in
                Button {
                    personaManager.selectPersona(persona)
                } label: {
                    Label {
                        VStack(alignment: .leading) {
                            Text(persona.displayName)
                            Text(persona.description)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: persona.icon)
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: personaManager.selectedPersona.icon)
                    .font(.system(size: 12))
                Text(personaManager.selectedPersona.displayName)
                    .font(.system(size: 12, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
        .menuStyle(.borderlessButton)
    }
}

#Preview("Persona Picker") {
    PersonaPickerView()
        .environmentObject(PersonaManager())
        .padding()
        .frame(width: 400)
}

#Preview("Compact Picker") {
    CompactPersonaPicker()
        .environmentObject(PersonaManager())
        .padding()
}
