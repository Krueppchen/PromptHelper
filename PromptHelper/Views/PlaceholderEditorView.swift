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
    @State private var editTags: [String]

    /// Neuer Options-Input
    @State private var newOptionInput: String = ""

    /// Neuer Tag-Input
    @State private var newTagInput: String = ""

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
        _editTags = State(initialValue: placeholder.tags)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // Icon & Titel
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: editType.iconName)
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(DesignSystem.SemanticColor.accent)

                        VStack(spacing: DesignSystem.Spacing.xs) {
                            TextField("Name des Platzhalters", text: $editLabel)
                                .font(.title2.weight(.semibold))
                                .multilineTextAlignment(.center)
                                .padding(DesignSystem.Spacing.sm)
                                .background(DesignSystem.SemanticColor.tertiaryBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                        .strokeBorder(
                                            editLabel.isEmpty ?
                                                DesignSystem.SemanticColor.error.opacity(0.3) :
                                                DesignSystem.SemanticColor.accent.opacity(0.3),
                                            lineWidth: 1
                                        )
                                )
                                .cornerRadius(DesignSystem.CornerRadius.sm)

                            if editLabel.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.caption)
                                    Text("Name ist erforderlich")
                                        .font(DesignSystem.Typography.caption)
                                }
                                .foregroundStyle(DesignSystem.SemanticColor.error)
                            }
                        }
                    }
                    .padding(.top, 20)

                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // Typ-Picker
                        formSection(title: "Typ", icon: "slider.horizontal.3") {
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
                        formSection(title: "Schlüssel", icon: "key.fill") {
                            Text("{{\(editKey)}}")
                                .font(.body.monospaced())
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(DesignSystem.Spacing.sm)
                                .background(DesignSystem.SemanticColor.accent.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                        .strokeBorder(DesignSystem.SemanticColor.accent.opacity(0.3), lineWidth: 1)
                                )
                                .cornerRadius(DesignSystem.CornerRadius.sm)
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
                            formSection(title: "Optionen", icon: "list.bullet") {
                                VStack(spacing: DesignSystem.Spacing.sm) {
                                    if !editOptions.isEmpty {
                                        VStack(spacing: DesignSystem.Spacing.xs) {
                                            ForEach(Array(editOptions.enumerated()), id: \.offset) { index, option in
                                                HStack {
                                                    Text(option)
                                                        .font(DesignSystem.Typography.body)
                                                    Spacer()
                                                    Button {
                                                        editOptions.remove(at: index)
                                                    } label: {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .foregroundStyle(.secondary)
                                                    }
                                                }
                                                .padding(DesignSystem.Spacing.sm)
                                                .background(DesignSystem.SemanticColor.tertiaryBackground)
                                                .cornerRadius(DesignSystem.CornerRadius.sm)
                                            }
                                        }
                                    } else {
                                        HStack {
                                            Image(systemName: "info.circle")
                                                .foregroundStyle(DesignSystem.SemanticColor.info)
                                            Text("Fügen Sie Optionen hinzu")
                                                .font(DesignSystem.Typography.caption)
                                                .foregroundStyle(DesignSystem.SemanticColor.secondary)
                                        }
                                        .padding(DesignSystem.Spacing.sm)
                                        .frame(maxWidth: .infinity)
                                        .background(DesignSystem.SemanticColor.info.opacity(0.1))
                                        .cornerRadius(DesignSystem.CornerRadius.sm)
                                    }

                                    HStack {
                                        TextField("Neue Option", text: $newOptionInput)
                                            .padding(DesignSystem.Spacing.sm)
                                            .background(DesignSystem.SemanticColor.tertiaryBackground)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                                    .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                                            )
                                            .cornerRadius(DesignSystem.CornerRadius.sm)

                                        Button {
                                            addOption()
                                        } label: {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.title2)
                                                .foregroundStyle(
                                                    newOptionInput.trimmingCharacters(in: .whitespaces).isEmpty ?
                                                        Color.secondary : DesignSystem.SemanticColor.accent
                                                )
                                        }
                                        .disabled(newOptionInput.trimmingCharacters(in: .whitespaces).isEmpty)
                                    }
                                }
                            }
                        }

                        // Standardwert
                        formSection(title: "Standardwert (optional)", icon: "text.quote") {
                            TextField("z.B. Beispieltext", text: $editDefaultValue)
                                .padding(DesignSystem.Spacing.sm)
                                .background(DesignSystem.SemanticColor.tertiaryBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                        .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                                )
                                .cornerRadius(DesignSystem.CornerRadius.sm)
                        }

                        // Tags
                        formSection(title: "Tags", icon: "tag.fill") {
                            VStack(spacing: DesignSystem.Spacing.sm) {
                                if !editTags.isEmpty {
                                    TagFlowLayout(spacing: 8) {
                                        ForEach(Array(editTags.enumerated()), id: \.offset) { index, tag in
                                            HStack(spacing: 4) {
                                                Text(tag)
                                                    .font(DesignSystem.Typography.caption)

                                                Button {
                                                    editTags.remove(at: index)
                                                } label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(DesignSystem.SemanticColor.accent.opacity(0.15))
                                            .foregroundStyle(DesignSystem.SemanticColor.accent)
                                            .cornerRadius(DesignSystem.CornerRadius.chip)
                                        }
                                    }
                                }

                                HStack {
                                    TextField("Neuer Tag", text: $newTagInput)
                                        .padding(DesignSystem.Spacing.sm)
                                        .background(DesignSystem.SemanticColor.tertiaryBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                                .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                                        )
                                        .cornerRadius(DesignSystem.CornerRadius.sm)
                                        .onSubmit {
                                            addTag()
                                        }

                                    Button {
                                        addTag()
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(
                                                newTagInput.trimmingCharacters(in: .whitespaces).isEmpty ?
                                                    Color.secondary : DesignSystem.SemanticColor.accent
                                            )
                                    }
                                    .disabled(newTagInput.trimmingCharacters(in: .whitespaces).isEmpty)
                                }
                            }
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

    @ViewBuilder
    private func formSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: DesignSystem.IconSize.sm))
                    .foregroundStyle(DesignSystem.SemanticColor.accent)

                Text(title)
                    .font(DesignSystem.Typography.subheadline.weight(.medium))
                    .foregroundStyle(DesignSystem.SemanticColor.secondary)
            }

            content()
        }
    }

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

    private func addTag() {
        let tag = newTagInput.trimmingCharacters(in: .whitespaces)
        guard !tag.isEmpty else { return }
        guard !editTags.contains(tag) else {
            newTagInput = ""
            return
        }

        editTags.append(tag)
        newTagInput = ""
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
        placeholder.tags = editTags
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
