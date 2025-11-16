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
                // Platzhalter-Liste
                ScrollView {
                    VStack(spacing: 16) {
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
                    .padding(16)
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
                VStack {
                    Spacer()

                    Button {
                        viewModel.generatePrompt()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Generieren")
                                .font(DesignSystem.Typography.bodyEmphasized)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                .fill(viewModel.allRequiredFilled ? DesignSystem.SemanticColor.accent : Color.secondary)
                                .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
                        )
                    }
                    .disabled(!viewModel.allRequiredFilled)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
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
                    .padding(.top, 8)
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
