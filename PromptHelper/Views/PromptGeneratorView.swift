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
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Header mit Hinweisen
                instructionHeader

                // Platzhalter-Liste
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        let placeholders = viewModel.sortedPlaceholders

                        if placeholders.isEmpty {
                            ModernEmptyState(
                                icon: "checkmark.circle",
                                title: "Bereit zur Verwendung",
                                message: "Dieses Template hat keine Platzhalter"
                            )
                            .padding(.top, 40)
                        } else {
                            ForEach(placeholders, id: \.id) { templatePlaceholder in
                                if let placeholder = templatePlaceholder.placeholder {
                                    PlaceholderInputView(
                                        placeholder: placeholder,
                                        value: Binding(
                                            get: {
                                                viewModel.filledValues[placeholder.key] ?? ""
                                            },
                                            set: { newValue in
                                                viewModel.filledValues[placeholder.key] = newValue
                                            }
                                        )
                                    )
                                }
                            }
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                    .padding(.bottom, 100)
                }

                // Generierter Prompt (wenn vorhanden)
                if !viewModel.generatedPrompt.isEmpty {
                    VStack(spacing: 0) {
                        Divider()

                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(DesignSystem.SemanticColor.successIcon)
                                Text("Fertiger Prompt")
                                    .font(DesignSystem.Typography.bodyEmphasized)
                                    .foregroundStyle(DesignSystem.SemanticColor.primary)
                                Spacer()
                                Button {
                                    viewModel.copyToClipboard()
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                    Text("Kopieren")
                                }
                                .buttonStyle(.bordered)
                                .tint(DesignSystem.SemanticColor.accent)
                            }

                            Text(viewModel.generatedPrompt)
                                .font(DesignSystem.Typography.body)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(DesignSystem.SemanticColor.tertiaryBackground)
                                .cornerRadius(DesignSystem.CornerRadius.md)
                        }
                        .padding(16)
                        .background(.ultraThinMaterial)
                    }
                }
            }

            // Generieren-Button
            if viewModel.generatedPrompt.isEmpty {
                generateButton
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
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(DesignSystem.Animation.smooth, value: viewModel.successMessage)
    }

    // MARK: - Instruction Header

    private var instructionHeader: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: DesignSystem.IconSize.sm))
                    .foregroundStyle(DesignSystem.SemanticColor.info)

                Text("Füllen Sie die Felder aus")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(DesignSystem.SemanticColor.primary)
            }

            HStack(spacing: 4) {
                Text("Pflichtfelder sind mit")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.SemanticColor.secondary)

                Text("*")
                    .font(DesignSystem.Typography.caption.weight(.semibold))
                    .foregroundStyle(DesignSystem.SemanticColor.error)

                Text("markiert")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.SemanticColor.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.SemanticColor.info.opacity(0.08))
        .overlay(
            Rectangle()
                .fill(DesignSystem.SemanticColor.info.opacity(0.3))
                .frame(width: 3),
            alignment: .leading
        )
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        VStack {
            Spacer()

            VStack(spacing: DesignSystem.Spacing.sm) {
                // Status-Info wenn nicht alle Felder ausgefüllt
                if !viewModel.allRequiredFilled {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption)
                        Text("Bitte alle Pflichtfelder ausfüllen")
                            .font(DesignSystem.Typography.caption)
                    }
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(Color.secondary)
                    .cornerRadius(DesignSystem.CornerRadius.sm)
                }

                Button {
                    viewModel.generatePrompt()
                } label: {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Prompt generieren")
                            .font(DesignSystem.Typography.bodyEmphasized)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .fill(viewModel.allRequiredFilled ? DesignSystem.SemanticColor.accent : Color.secondary)
                            .shadow(
                                color: viewModel.allRequiredFilled ?
                                    DesignSystem.SemanticColor.accent.opacity(0.3) : Color.clear,
                                radius: 12,
                                y: 4
                            )
                    )
                }
                .disabled(!viewModel.allRequiredFilled)
                .animation(DesignSystem.Animation.smooth, value: viewModel.allRequiredFilled)
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.bottom, DesignSystem.Spacing.md)
        }
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
