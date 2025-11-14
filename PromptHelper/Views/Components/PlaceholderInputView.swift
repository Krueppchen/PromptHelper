//
//  PlaceholderInputView.swift
//  PromptHelper
//
//  Created by Claude Code on 2025-11-14.
//

import SwiftUI

/// Wiederverwendbare Input-View für Platzhalter
/// Zeigt das passende Input-Element basierend auf dem Platzhalter-Typ
struct PlaceholderInputView: View {
    let placeholder: PlaceholderDefinition
    @Binding var value: String

    /// Für MultiChoice: Temporärer State für ausgewählte Werte
    @State private var selectedMultiChoiceValues: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label mit optional Beschreibung
            VStack(alignment: .leading, spacing: 4) {
                Text(placeholder.label)
                    .font(.headline)

                if let description = placeholder.descriptionText, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Input basierend auf Typ
            switch placeholder.type {
            case .text:
                TextField("Eingabe...", text: $value)
                    .textFieldStyle(.roundedBorder)

            case .number:
                TextField("Zahl eingeben...", text: $value)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)

            case .date:
                DatePicker(
                    "Datum wählen",
                    selection: Binding(
                        get: {
                            if let date = ISO8601DateFormatter().date(from: value) {
                                return date
                            }
                            return Date()
                        },
                        set: { newDate in
                            value = ISO8601DateFormatter().string(from: newDate)
                        }
                    ),
                    displayedComponents: [.date]
                )

            case .singleChoice:
                if placeholder.options.isEmpty {
                    Text("Keine Optionen definiert")
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Auswahl", selection: $value) {
                        Text("Bitte wählen...").tag("")
                        ForEach(placeholder.options, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                }

            case .multiChoice:
                if placeholder.options.isEmpty {
                    Text("Keine Optionen definiert")
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(placeholder.options, id: \.self) { option in
                            Toggle(option, isOn: Binding(
                                get: {
                                    selectedMultiChoiceValues.contains(option)
                                },
                                set: { isSelected in
                                    if isSelected {
                                        selectedMultiChoiceValues.insert(option)
                                    } else {
                                        selectedMultiChoiceValues.remove(option)
                                    }
                                    // Update value als komma-separierte Liste
                                    value = selectedMultiChoiceValues.sorted().joined(separator: ", ")
                                }
                            ))
                        }
                    }
                    .onAppear {
                        // Initialisiere selectedValues aus value
                        if !value.isEmpty {
                            selectedMultiChoiceValues = Set(
                                value.components(separatedBy: ",")
                                    .map { $0.trimmingCharacters(in: .whitespaces) }
                            )
                        }
                    }
                }
            }
        }
        .onAppear {
            // Setze Standardwert, wenn value leer ist
            if value.isEmpty, let defaultValue = placeholder.defaultValue {
                value = defaultValue
            }
        }
    }
}

// MARK: - Previews

#Preview("Text Input") {
    PlaceholderInputView(
        placeholder: PlaceholderDefinition(
            key: "test",
            label: "Test Platzhalter",
            type: .text,
            descriptionText: "Dies ist eine Beschreibung"
        ),
        value: .constant("")
    )
    .padding()
}

#Preview("Single Choice") {
    PlaceholderInputView(
        placeholder: PlaceholderDefinition(
            key: "tonalitaet",
            label: "Tonalität",
            type: .singleChoice,
            options: ["Professionell", "Freundlich", "Witzig"]
        ),
        value: .constant("")
    )
    .padding()
}

#Preview("Multi Choice") {
    PlaceholderInputView(
        placeholder: PlaceholderDefinition(
            key: "features",
            label: "Features",
            type: .multiChoice,
            options: ["Feature A", "Feature B", "Feature C"]
        ),
        value: .constant("")
    )
    .padding()
}
