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
                // Kompakter Header
                VStack(spacing: 8) {
                    Text(template.title)
                        .font(.title3.weight(.semibold))

                    if !viewModel.sortedPlaceholders.isEmpty {
                        let filled = viewModel.filledValues.filter { !$0.value.isEmpty }.count
                        let total = viewModel.sortedPlaceholders.count
                        HStack(spacing: 4) {
                            Image(systemName: filled == total ? "checkmark.circle.fill" : "circle.dashed")
                                .foregroundStyle(filled == total ? .green : .secondary)
                            Text("\(filled) von \(total) ausgefüllt")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)

                Divider()

                // Platzhalter-Liste
                ScrollView {
                    VStack(spacing: 20) {
                        let placeholders = viewModel.sortedPlaceholders

                        if placeholders.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.green)
                                Text("Keine Platzhalter")
                                    .font(.headline)
                                Text("Dieses Template ist bereit zur Verwendung")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 60)
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
                    .padding(20)
                    .padding(.bottom, 100)
                }

                // Ergebnis (wenn generiert)
                if !viewModel.generatedPrompt.isEmpty {
                    VStack(spacing: 0) {
                        Divider()

                        VStack(spacing: 12) {
                            HStack {
                                Label("Ihr Prompt", systemImage: "checkmark.circle.fill")
                                    .font(.headline)
                                    .foregroundStyle(.green)
                                Spacer()
                                Button {
                                    viewModel.copyToClipboard()
                                } label: {
                                    Label("Kopieren", systemImage: "doc.on.doc")
                                        .font(.subheadline.weight(.medium))
                                }
                                .buttonStyle(.bordered)
                            }

                            Text(viewModel.generatedPrompt)
                                .font(.body)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        .padding(20)
                        .background(.ultraThinMaterial)
                    }
                }
            }

            // Floating Action Button
            if viewModel.generatedPrompt.isEmpty {
                Button {
                    viewModel.generatePrompt()
                } label: {
                    HStack {
                        Image(systemName: "wand.and.stars.inverse")
                        Text("Generieren")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(viewModel.allRequiredFilled ? Color.accentColor : Color.secondary)
                            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                    )
                }
                .disabled(!viewModel.allRequiredFilled)
                .padding(.bottom, 24)
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
