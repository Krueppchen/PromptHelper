//
//  PromptGeneratorView.swift
//  PromptHelper
//
//  Created by Claude Code on 2025-11-14.
//

import SwiftUI
import SwiftData

/// Generator-View für Prompts
/// Ermöglicht das Ausfüllen von Platzhaltern und Generieren des finalen Prompts
struct PromptGeneratorView: View {
    @Environment(\.modelContext) private var modelContext

    /// Das Template
    let template: PromptTemplate

    /// ViewModel
    @State private var viewModel: PromptGeneratorViewModel?

    var body: some View {
        Group {
            if let viewModel = viewModel {
                generatorContent(viewModel: viewModel)
            } else {
                ProgressView()
                    .onAppear {
                        viewModel = PromptGeneratorViewModel(template: template, context: modelContext)
                    }
            }
        }
        .navigationTitle("Prompt generieren")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subviews

    @ViewBuilder
    private func generatorContent(viewModel: PromptGeneratorViewModel) -> some View {
        Form {
            // Template-Info
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(template.title)
                        .font(.headline)

                    if let description = template.descriptionText, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Platzhalter-Eingaben
            Section("Platzhalter ausfüllen") {
                let placeholders = viewModel.sortedPlaceholders

                if placeholders.isEmpty {
                    Text("Dieses Template hat keine Platzhalter")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(placeholders, id: \.id) { templatePlaceholder in
                        if let placeholder = templatePlaceholder.placeholder {
                            VStack(alignment: .leading, spacing: 4) {
                                PlaceholderInputView(
                                    placeholder: placeholder,
                                    value: Binding(
                                        get: {
                                            viewModel.filledValues[placeholder.key] ?? ""
                                        },
                                        set: { newValue in
                                            viewModel.filledValues[placeholder.key] = newValue
                                            if viewModel.showPreview {
                                                viewModel.updatePreview()
                                            }
                                        }
                                    )
                                )

                                if templatePlaceholder.isRequired {
                                    Label("Pflichtfeld", systemImage: "asterisk")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }

            // Aktionen
            Section {
                Toggle("Live-Vorschau", isOn: $viewModel.showPreview)
                    .onChange(of: viewModel.showPreview) { _, isOn in
                        if isOn {
                            viewModel.updatePreview()
                        }
                    }

                Button {
                    viewModel.generatePrompt()
                } label: {
                    Label("Prompt generieren", systemImage: "wand.and.stars")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.allRequiredFilled)

                Button {
                    viewModel.reset()
                } label: {
                    Label("Zurücksetzen", systemImage: "arrow.counterclockwise")
                }
            }

            // Generierter Prompt
            if !viewModel.generatedPrompt.isEmpty {
                Section("Generierter Prompt") {
                    Text(viewModel.generatedPrompt)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    HStack {
                        Text("\(viewModel.generatedPrompt.count) Zeichen")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button {
                            viewModel.copyToClipboard()
                        } label: {
                            Label("Kopieren", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .alert("Fehler", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
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
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        if let template = try? PersistenceController.preview.mainContext.fetch(
            FetchDescriptor<PromptTemplate>()
        ).first {
            PromptGeneratorView(template: template)
                .modelContainer(PersistenceController.preview.container)
        }
    }
}
