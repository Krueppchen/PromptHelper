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
    @State private var viewModel: PromptGeneratorViewModel

    init(template: PromptTemplate) {
        self.template = template
        let tempContext = ModelContext(PersistenceController.shared.container)
        _viewModel = State(initialValue: PromptGeneratorViewModel(template: template, context: tempContext))
    }

    var body: some View {
        generatorContent
            .navigationTitle("Prompt generieren")
            .navigationBarTitleDisplayMode(.inline)
            .background(DesignSystem.SemanticColor.background)
            .onAppear {
                if viewModel.context !== modelContext {
                    viewModel = PromptGeneratorViewModel(template: template, context: modelContext)
                }
            }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var generatorContent: some View {
        Form {
            // Template-Info mit verbessertem Design
            Section {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.accentColor.opacity(0.15))
                            .frame(width: 50, height: 50)

                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.title)
                            .font(.headline)

                        if let description = template.descriptionText, !description.isEmpty {
                            Text(description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            // Platzhalter-Eingaben
            Section {
                let placeholders = viewModel.sortedPlaceholders

                if placeholders.isEmpty {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text("Dieses Template hat keine Platzhalter zum Ausfüllen")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(placeholders, id: \.id) { templatePlaceholder in
                        if let placeholder = templatePlaceholder.placeholder {
                            VStack(alignment: .leading, spacing: 8) {
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
                                    HStack(spacing: 4) {
                                        Image(systemName: "asterisk.circle.fill")
                                            .font(.caption2)
                                        Text("Pflichtfeld")
                                            .font(.caption2)
                                    }
                                    .foregroundStyle(.orange)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Platzhalter ausfüllen")
                    Spacer()
                    if !viewModel.sortedPlaceholders.isEmpty {
                        Text("\(viewModel.filledValues.count)/\(viewModel.sortedPlaceholders.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } footer: {
                if !viewModel.sortedPlaceholders.isEmpty {
                    Text("Füllen Sie alle Platzhalter aus, um Ihren personalisierten Prompt zu generieren")
                }
            }

            // Aktionen
            Section("Aktionen") {
                Toggle(isOn: $viewModel.showPreview) {
                    Label("Live-Vorschau", systemImage: "eye")
                }
                .onChange(of: viewModel.showPreview) { _, isOn in
                    if isOn {
                        viewModel.updatePreview()
                    }
                }

                Button {
                    viewModel.generatePrompt()
                } label: {
                    HStack {
                        Label("Prompt generieren", systemImage: "wand.and.stars")
                        Spacer()
                        if !viewModel.allRequiredFilled {
                            Text("Felder ausfüllen")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.allRequiredFilled)

                Button(role: .destructive) {
                    viewModel.reset()
                } label: {
                    Label("Zurücksetzen", systemImage: "arrow.counterclockwise")
                }
            }

            // Generierter Prompt mit verbessertem Design
            if !viewModel.generatedPrompt.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(viewModel.generatedPrompt)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.secondary.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                            )

                        HStack(spacing: 16) {
                            Label("\(viewModel.generatedPrompt.count)", systemImage: "textformat.size")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Button {
                                viewModel.copyToClipboard()
                            } label: {
                                Label("Kopieren", systemImage: "doc.on.doc")
                                    .font(.subheadline)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                } header: {
                    Label("Generierter Prompt", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
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
                ModernToast(message: success, type: .success)
                    .padding(.top, DesignSystem.Spacing.sm)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(DesignSystem.Animation.smooth, value: viewModel.successMessage)
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
