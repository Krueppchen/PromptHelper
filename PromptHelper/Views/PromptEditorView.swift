//
//  PromptEditorView.swift
//  PromptHelper
//
//  Created by Claude Code on 2025-11-14.
//

import SwiftUI
import SwiftData

/// Editor-View für Prompt-Templates
struct PromptEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// Das zu bearbeitende Template
    let template: PromptTemplate

    /// ViewModel
    @State private var viewModel: PromptEditorViewModel?

    /// Navigation-State
    @State private var showGenerator = false

    var body: some View {
        Group {
            if let viewModel = viewModel {
                editorContent(viewModel: viewModel)
            } else {
                ProgressView()
                    .onAppear {
                        viewModel = PromptEditorViewModel(template: template, context: modelContext)
                    }
            }
        }
        .navigationTitle("Template bearbeiten")
        .navigationBarTitleDisplayMode(.inline)
        .background(DesignSystem.SemanticColor.background)
    }

    // MARK: - Subviews

    @ViewBuilder
    private func editorContent(viewModel: PromptEditorViewModel) -> some View {
        @Bindable var bindableViewModel = viewModel
        @Bindable var bindableTemplate = template

        Form {
            // Basis-Informationen
            Section("Informationen") {
                TextField("Titel", text: $bindableViewModel.editTitle)

                TextField("Beschreibung (optional)", text: $bindableViewModel.editDescription, axis: .vertical)
                    .lineLimit(3...6)
            }

            // Content-Editor
            Section {
                TextEditor(text: $bindableViewModel.editContent)
                    .frame(minHeight: 200)
                    .font(.system(.body, design: .monospaced))
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    // Platzhalter einfügen
                                    Button {
                                        insertPlaceholder(into: $bindableViewModel.editContent)
                                    } label: {
                                        Label("Platzhalter", systemImage: "curlybraces")
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.accentColor)
                                            .foregroundStyle(.white)
                                            .clipShape(Capsule())
                                    }

                                    // Einzelne Klammern für manuelle Eingabe
                                    Button {
                                        bindableViewModel.editContent += "{{"
                                    } label: {
                                        Text("{{")
                                            .font(.system(.body, design: .monospaced))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color.secondary.opacity(0.2))
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }

                                    Button {
                                        bindableViewModel.editContent += "}}"
                                    } label: {
                                        Text("}}")
                                            .font(.system(.body, design: .monospaced))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color.secondary.opacity(0.2))
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }

                                    Spacer()
                                }
                            }
                        }
                    }

                HStack {
                    Text("\(bindableViewModel.editContent.count) Zeichen")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    let placeholderCount = viewModel.getDetectedPlaceholderKeys().count
                    Label("\(placeholderCount) Platzhalter", systemImage: "curlybraces")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Prompt-Inhalt")
            } footer: {
                Text("Verwenden Sie {{key}} für Platzhalter oder nutzen Sie die Tastatur-Toolbar")
            }

            // Platzhalter-Verwaltung
            Section {
                let detectedKeys = viewModel.getDetectedPlaceholderKeys()

                if detectedKeys.isEmpty {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text("Tippen Sie {{name}} um einen Platzhalter zu erstellen")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(detectedKeys, id: \.self) { key in
                        HStack {
                            Text("{{\(key)}}")
                                .font(.system(.body, design: .monospaced))

                            Spacer()

                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                        }
                    }

                    if viewModel.isAutoSyncing {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("Synchronisiere...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Platzhalter")
            } footer: {
                Text("Platzhalter werden automatisch erkannt und erstellt")
            }

            // Tags
            Section("Tags") {
                // Bestehende Tags
                if !bindableViewModel.editTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(bindableViewModel.editTags, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text(tag)
                                    Button {
                                        viewModel.removeTag(tag)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                            }
                        }
                    }
                }

                // Neuer Tag
                HStack {
                    TextField("Neuer Tag", text: $bindableViewModel.newTagInput)
                        .onSubmit {
                            viewModel.addTag()
                        }

                    Button("Hinzufügen") {
                        viewModel.addTag()
                    }
                    .disabled(bindableViewModel.newTagInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            // Aktionen
            Section {
                Button {
                    showGenerator = true
                } label: {
                    Label("Prompt generieren", systemImage: "wand.and.stars")
                }

                Toggle("Als Favorit markieren", isOn: $bindableTemplate.isFavorite)
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Speichern") {
                    viewModel.save()
                }
            }
        }
        .alert("Fehler", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                bindableViewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .overlay(alignment: .top) {
            if let success = viewModel.successMessage {
                ModernToast(message: success, type: .success)
                    .padding(.top, DesignSystem.Spacing.sm)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(DesignSystem.Animation.smooth, value: viewModel.successMessage)
        .navigationDestination(isPresented: $showGenerator) {
            PromptGeneratorView(template: template)
        }
    }

    // MARK: - Helper Methods

    /// Fügt einen Platzhalter an der aktuellen Position ein
    private func insertPlaceholder(into binding: Binding<String>) {
        // Füge Platzhalter-Template ein
        binding.wrappedValue += "{{}}"
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        if let template = try? PersistenceController.preview.mainContext.fetch(
            FetchDescriptor<PromptTemplate>()
        ).first {
            PromptEditorView(template: template)
                .modelContainer(PersistenceController.preview.container)
        }
    }
}
