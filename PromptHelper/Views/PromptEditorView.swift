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
                Text("Verwenden Sie {{key}} für Platzhalter")
            }

            // Platzhalter-Verwaltung
            Section("Platzhalter") {
                let detectedKeys = viewModel.getDetectedPlaceholderKeys()
                let missingKeys = viewModel.getMissingPlaceholderDefinitions()

                if detectedKeys.isEmpty {
                    Text("Keine Platzhalter gefunden")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(detectedKeys, id: \.self) { key in
                        HStack {
                            Text("{{\(key)}}")
                                .font(.system(.body, design: .monospaced))

                            Spacer()

                            if missingKeys.contains(key) {
                                Label("Nicht definiert", systemImage: "exclamationmark.triangle")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                            }
                        }
                    }

                    Button {
                        viewModel.detectAndSyncPlaceholders()
                    } label: {
                        Label("Platzhalter synchronisieren", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
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
                Text(success)
                    .font(.headline)
                    .padding()
                    .background(.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: viewModel.successMessage)
        .navigationDestination(isPresented: $showGenerator) {
            PromptGeneratorView(template: template)
        }
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
