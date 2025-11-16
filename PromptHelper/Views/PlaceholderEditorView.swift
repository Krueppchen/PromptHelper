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
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // Icon & Titel
                    VStack(spacing: 12) {
                        Image(systemName: editType.iconName)
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(Color.accentColor)

                        TextField("Name des Platzhalters", text: $editLabel)
                            .font(.title2.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .textFieldStyle(.plain)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 16) {
                        // Typ-Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Typ")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)

                            Picker("Typ", selection: $editType) {
                                ForEach(PlaceholderType.allCases, id: \.self) { type in
                                    Label(type.displayName, systemImage: type.iconName).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: editType) { _, newType in
                                if !newType.requiresOptions {
                                    editOptions.removeAll()
                                }
                            }
                        }

                        // Key (automatisch generiert)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Schlüssel")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)

                            Text("{{\(editKey)}}")
                                .font(.body.monospaced())
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color.accentColor.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .onAppear {
                            if editKey == "neuer_platzhalter" {
                                editKey = PlaceholderDetectionService().suggestKey(from: editLabel)
                            }
                        }
                        .onChange(of: editLabel) { _, newLabel in
                            editKey = PlaceholderDetectionService().suggestKey(from: newLabel)
                        }

                        // Optionen (wenn nötig)
                        if editType.requiresOptions {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Optionen")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)

                                if !editOptions.isEmpty {
                                    VStack(spacing: 8) {
                                        ForEach(Array(editOptions.enumerated()), id: \.offset) { index, option in
                                            HStack {
                                                Text(option)
                                                Spacer()
                                                Button {
                                                    editOptions.remove(at: index)
                                                } label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                            .padding(12)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(8)
                                        }
                                    }
                                }

                                HStack {
                                    TextField("Neue Option", text: $newOptionInput)
                                        .textFieldStyle(.roundedBorder)

                                    Button {
                                        addOption()
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                    }
                                    .disabled(newOptionInput.trimmingCharacters(in: .whitespaces).isEmpty)
                                }
                            }
                        }

                        // Standardwert
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Standardwert (optional)")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)

                            TextField("z.B. Beispieltext", text: $editDefaultValue)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Platzhalter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Fertig") {
                    save()
                }
                .font(.body.weight(.semibold))
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
                    .padding(.top, 8)
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
