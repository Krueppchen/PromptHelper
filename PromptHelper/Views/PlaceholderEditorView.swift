//
//  PlaceholderEditorView.swift
//  PromptHelper
//
//  Created by Claude Code on 2025-11-14.
//

import SwiftUI
import SwiftData

/// Editor-View für Platzhalter-Definitionen
struct PlaceholderEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// Der zu bearbeitende Platzhalter
    @Bindable var placeholder: PlaceholderDefinition

    /// Temporäre Editier-Werte
    @State private var editKey: String
    @State private var editLabel: String
    @State private var editType: PlaceholderType
    @State private var editOptions: [String]
    @State private var editDefaultValue: String
    @State private var editDescription: String

    /// Neuer Options-Input
    @State private var newOptionInput: String = ""

    /// Fehler und Erfolg
    @State private var errorMessage: String?
    @State private var successMessage: String?

    init(placeholder: PlaceholderDefinition) {
        self.placeholder = placeholder
        _editKey = State(initialValue: placeholder.key)
        _editLabel = State(initialValue: placeholder.label)
        _editType = State(initialValue: placeholder.type)
        _editOptions = State(initialValue: placeholder.options)
        _editDefaultValue = State(initialValue: placeholder.defaultValue ?? "")
        _editDescription = State(initialValue: placeholder.descriptionText ?? "")
    }

    var body: some View {
        Form {
            // Basis-Informationen
            Section("Informationen") {
                TextField("Label", text: $editLabel)

                HStack {
                    TextField("Schlüssel", text: $editKey)
                        .font(.system(.body, design: .monospaced))
                        .autocapitalization(.none)

                    Button {
                        editKey = PlaceholderDetectionService().suggestKey(from: editLabel)
                    } label: {
                        Image(systemName: "wand.and.stars")
                    }
                }

                TextField("Beschreibung (optional)", text: $editDescription, axis: .vertical)
                    .lineLimit(2...4)
            }

            // Typ und Einstellungen
            Section("Typ") {
                Picker("Platzhalter-Typ", selection: $editType) {
                    ForEach(PlaceholderType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .onChange(of: editType) { _, newType in
                    // Lösche Optionen, wenn nicht mehr benötigt
                    if !newType.requiresOptions {
                        editOptions.removeAll()
                    }
                }
            }

            // Optionen für Choice-Typen
            if editType.requiresOptions {
                Section {
                    if editOptions.isEmpty {
                        Text("Noch keine Optionen definiert")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(editOptions.enumerated()), id: \.offset) { index, option in
                            HStack {
                                Text("\(index + 1).")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 30)

                                Text(option)

                                Spacer()

                                Button {
                                    editOptions.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        .onMove { from, to in
                            editOptions.move(fromOffsets: from, toOffset: to)
                        }
                    }

                    // Neue Option hinzufügen
                    HStack {
                        TextField("Neue Option", text: $newOptionInput)
                            .onSubmit {
                                addOption()
                            }

                        Button("Hinzufügen") {
                            addOption()
                        }
                        .disabled(newOptionInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } header: {
                    Text("Optionen")
                } footer: {
                    Text("Definieren Sie die möglichen Werte für die Auswahl")
                }
            }

            // Erweiterte Einstellungen
            Section {
                TextField("Standardwert (optional)", text: $editDefaultValue)
            } header: {
                Text("Einstellungen")
            } footer: {
                Text("Der Standardwert wird automatisch eingesetzt, wenn Sie einen neuen Prompt erstellen")
            }

            // Vorschau
            Section("Vorschau") {
                PlaceholderInputView(
                    placeholder: PlaceholderDefinition(
                        key: editKey,
                        label: editLabel,
                        type: editType,
                        options: editOptions,
                        defaultValue: editDefaultValue.isEmpty ? nil : editDefaultValue
                    ),
                    value: .constant("")
                )
            }
        }
        .navigationTitle("Platzhalter bearbeiten")
        .navigationBarTitleDisplayMode(.inline)
        .background(DesignSystem.SemanticColor.background)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Speichern") {
                    save()
                }
            }
        }
        .alert("Fehler", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .overlay(alignment: .top) {
            if let success = successMessage {
                ModernToast(message: success, type: .success)
                    .padding(.top, DesignSystem.Spacing.sm)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(DesignSystem.Animation.smooth, value: successMessage)
    }

    // MARK: - Helper Methods

    private func addOption() {
        let option = newOptionInput.trimmingCharacters(in: .whitespaces)
        guard !option.isEmpty else { return }
        guard !editOptions.contains(option) else {
            newOptionInput = ""
            return
        }

        editOptions.append(option)
        newOptionInput = ""
    }

    private func save() {
        // Validierung
        guard !editLabel.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Das Label darf nicht leer sein."
            return
        }

        guard !editKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Der Schlüssel darf nicht leer sein."
            return
        }

        guard editKey.isValidPlaceholderKey() else {
            errorMessage = "Der Schlüssel enthält ungültige Zeichen."
            return
        }

        if editType.requiresOptions && editOptions.isEmpty {
            errorMessage = "Für Auswahl-Platzhalter müssen Optionen definiert werden."
            return
        }

        // Aktualisiere Platzhalter
        placeholder.key = editKey
        placeholder.label = editLabel
        placeholder.type = editType
        placeholder.options = editOptions
        placeholder.isGlobal = true // Alle Platzhalter sind jetzt standardmäßig global
        placeholder.defaultValue = editDefaultValue.isEmpty ? nil : editDefaultValue
        placeholder.descriptionText = editDescription.isEmpty ? nil : editDescription
        placeholder.updatedAt = Date()

        // Speichere Context
        do {
            try modelContext.save()
            successMessage = "Gespeichert"

            // Verstecke Success-Message nach 2 Sekunden
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                successMessage = nil
            }
        } catch {
            errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        if let placeholder = try? PersistenceController.preview.mainContext.fetch(
            FetchDescriptor<PlaceholderDefinition>()
        ).first {
            PlaceholderEditorView(placeholder: placeholder)
                .modelContainer(PersistenceController.preview.container)
        }
    }
}
