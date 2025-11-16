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

    /// Fokus-State für bessere visuelle Rückmeldung
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Label mit Pflichtfeld-Indikator und Beschreibung
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                HStack(spacing: 4) {
                    Text(placeholder.label)
                        .font(DesignSystem.Typography.bodyEmphasized)
                        .foregroundStyle(DesignSystem.SemanticColor.primary)

                    if placeholder.isRequired {
                        Text("*")
                            .font(DesignSystem.Typography.bodyEmphasized)
                            .foregroundStyle(DesignSystem.SemanticColor.error)
                    }

                    Spacer()

                    // Status-Indikator
                    if !value.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(DesignSystem.SemanticColor.successIcon)
                    } else if placeholder.isRequired {
                        Image(systemName: "circle")
                            .font(.caption)
                            .foregroundStyle(.secondary.opacity(0.5))
                    }
                }

                if let description = placeholder.descriptionText, !description.isEmpty {
                    Text(description)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.SemanticColor.secondary)
                }
            }

            // Input basierend auf Typ
            inputView
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.SemanticColor.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .strokeBorder(borderColor, lineWidth: borderWidth)
        )
        .cornerRadius(DesignSystem.CornerRadius.md)
        .shadow(
            color: isFocused ? DesignSystem.SemanticColor.accent.opacity(0.2) : Color.clear,
            radius: 8,
            y: 2
        )
        .animation(DesignSystem.Animation.quick, value: isFocused)
        .animation(DesignSystem.Animation.quick, value: value.isEmpty)
        .onAppear {
            // Setze Standardwert, wenn value leer ist
            if value.isEmpty, let defaultValue = placeholder.defaultValue {
                value = defaultValue
            }
        }
    }

    // MARK: - Computed Properties

    private var borderColor: Color {
        if isFocused {
            return DesignSystem.SemanticColor.accent
        } else if placeholder.isRequired && value.isEmpty {
            return DesignSystem.SemanticColor.error.opacity(0.3)
        } else if !value.isEmpty {
            return DesignSystem.SemanticColor.successIcon.opacity(0.5)
        } else {
            return Color.secondary.opacity(0.2)
        }
    }

    private var borderWidth: CGFloat {
        isFocused ? 2 : 1
    }

    // MARK: - Input View

    @ViewBuilder
    private var inputView: some View {
        switch placeholder.type {
        case .text:
            TextField(placeholder.defaultValue ?? "Eingabe...", text: $value)
                .focused($isFocused)
                .font(DesignSystem.Typography.body)
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.SemanticColor.tertiaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .strokeBorder(
                            isFocused ? DesignSystem.SemanticColor.accent.opacity(0.5) : Color.clear,
                            lineWidth: 1
                        )
                )
                .cornerRadius(DesignSystem.CornerRadius.sm)

        case .number:
            TextField(placeholder.defaultValue ?? "z.B. 42", text: $value)
                .focused($isFocused)
                .keyboardType(.decimalPad)
                .font(DesignSystem.Typography.body)
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.SemanticColor.tertiaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .strokeBorder(
                            isFocused ? DesignSystem.SemanticColor.accent.opacity(0.5) : Color.clear,
                            lineWidth: 1
                        )
                )
                .cornerRadius(DesignSystem.CornerRadius.sm)

        case .date:
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(DesignSystem.SemanticColor.secondary)
                    .font(.system(size: DesignSystem.IconSize.sm))

                DatePicker(
                    "",
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
                .labelsHidden()
                .font(DesignSystem.Typography.body)
            }
            .padding(DesignSystem.Spacing.sm)
            .background(DesignSystem.SemanticColor.tertiaryBackground)
            .cornerRadius(DesignSystem.CornerRadius.sm)

        case .singleChoice:
            if placeholder.options.isEmpty {
                emptyOptionsView
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Image(systemName: "chevron.down.circle.fill")
                            .font(.system(size: DesignSystem.IconSize.sm))
                            .foregroundStyle(DesignSystem.SemanticColor.accent)

                        Picker("", selection: $value) {
                            Text("Bitte wählen...").tag("")
                            ForEach(placeholder.options, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .font(DesignSystem.Typography.body)
                        .tint(DesignSystem.SemanticColor.primary)
                    }
                    .padding(DesignSystem.Spacing.sm)
                    .background(DesignSystem.SemanticColor.tertiaryBackground)
                    .cornerRadius(DesignSystem.CornerRadius.sm)
                }
            }

        case .multiChoice:
            if placeholder.options.isEmpty {
                emptyOptionsView
            } else {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    ForEach(placeholder.options, id: \.self) { option in
                        Toggle(isOn: Binding(
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
                        )) {
                            Text(option)
                                .font(DesignSystem.Typography.body)
                        }
                        .tint(DesignSystem.SemanticColor.accent)
                        .padding(.vertical, DesignSystem.Spacing.xxs)
                    }
                }
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.SemanticColor.tertiaryBackground)
                .cornerRadius(DesignSystem.CornerRadius.sm)
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

    private var emptyOptionsView: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(DesignSystem.SemanticColor.warning)
            Text("Keine Optionen definiert")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.SemanticColor.secondary)
        }
        .padding(DesignSystem.Spacing.sm)
        .frame(maxWidth: .infinity)
        .background(DesignSystem.SemanticColor.warning.opacity(0.1))
        .cornerRadius(DesignSystem.CornerRadius.sm)
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
