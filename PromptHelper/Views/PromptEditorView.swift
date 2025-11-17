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
    @State private var showPlaceholderPicker = false

    /// Query für alle Platzhalter
    @Query(sort: \PlaceholderDefinition.label) private var allPlaceholders: [PlaceholderDefinition]

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
        .background(DesignSystem.SemanticColor.background)
    }

    // MARK: - Subviews

    @ViewBuilder
    private func editorContent(viewModel: PromptEditorViewModel) -> some View {
        @Bindable var bindableViewModel = viewModel
        @Bindable var bindableTemplate = template

        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // Kompakte Header-Leiste
                VStack(spacing: 8) {
                    TextField("Titel", text: $bindableViewModel.editTitle)
                        .font(.title2.weight(.semibold))
                        .textFieldStyle(.plain)

                    HStack(spacing: 12) {
                        // Zeichen & Platzhalter Counter
                        HStack(spacing: 4) {
                            Image(systemName: "text.alignleft")
                                .font(.caption)
                            Text("\(bindableViewModel.editContent.count)")
                                .font(.caption.monospacedDigit())
                        }
                        .foregroundStyle(.secondary)

                        let placeholderCount = viewModel.getDetectedPlaceholderKeys().count
                        HStack(spacing: 4) {
                            Image(systemName: "curlybraces")
                                .font(.caption)
                            Text("\(placeholderCount)")
                                .font(.caption.monospacedDigit())
                        }
                        .foregroundStyle(.secondary)

                        if viewModel.isAutoSyncing {
                            ProgressView()
                                .controlSize(.mini)
                        }

                        Spacer()

                        // Quick Actions
                        Button {
                            bindableTemplate.isFavorite.toggle()
                        } label: {
                            Image(systemName: bindableTemplate.isFavorite ? "star.fill" : "star")
                                .foregroundStyle(bindableTemplate.isFavorite ? .yellow : .secondary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)

                Divider()

                // Info-Banner für Editor
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "text.cursor")
                            .font(.system(size: DesignSystem.IconSize.sm))
                            .foregroundStyle(DesignSystem.SemanticColor.accent)

                        Text("Prompt-Template bearbeiten")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.SemanticColor.secondary)

                        Spacer()

                        Text("Tippen Sie hier, um zu beginnen")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.SemanticColor.accent)
                            .opacity(bindableViewModel.editContent.isEmpty ? 1 : 0)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(DesignSystem.SemanticColor.accent.opacity(0.05))

                // Großer Editor - mit Syntax-Highlighting für Platzhalter
                ZStack(alignment: .topLeading) {
                    // Placeholder Text wenn leer
                    if bindableViewModel.editContent.isEmpty {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("Beginnen Sie mit dem Schreiben...")
                                .font(.system(size: 17, design: .default))
                                .foregroundStyle(Color.secondary.opacity(0.5))

                            Text("💡 Tipp: Fügen Sie Platzhalter wie {{name}} hinzu")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.SemanticColor.accent.opacity(0.7))
                        }
                        .padding(20)
                        .allowsHitTesting(false)
                    }

                    HighlightedTextEditor(
                        text: $bindableViewModel.editContent,
                        placeholder: "Beginnen Sie mit dem Schreiben...",
                        highlightColor: UIColor(DesignSystem.SemanticColor.primary)
                    )
                    .opacity(bindableViewModel.editContent.isEmpty ? 0.5 : 1)
                }
                .background(
                    RoundedRectangle(cornerRadius: 0)
                        .fill(DesignSystem.SemanticColor.background)
                        .overlay(
                            RoundedRectangle(cornerRadius: 0)
                                .strokeBorder(
                                    bindableViewModel.editContent.isEmpty ?
                                        DesignSystem.SemanticColor.accent.opacity(0.2) : Color.clear,
                                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                                )
                        )
                )
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        HStack(spacing: 8) {
                            Button {
                                showPlaceholderPicker = true
                            } label: {
                                Label("Platzhalter", systemImage: "curlybraces")
                                    .font(.subheadline.weight(.medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.accentColor)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }

                            Spacer()

                            Button("Fertig") {
                                hideKeyboard()
                            }
                            .font(.subheadline.weight(.medium))
                        }
                    }
                }
            }

            // Floating Action Button für Generator
            Button {
                showGenerator = true
            } label: {
                HStack {
                    Image(systemName: "wand.and.stars.inverse")
                    Text("Generieren")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(Color.accentColor)
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                )
            }
            .padding(24)
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Fertig") {
                    viewModel.save()
                    dismiss()
                }
                .font(.body.weight(.semibold))
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
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(DesignSystem.Animation.smooth, value: viewModel.successMessage)
        .navigationDestination(isPresented: $showGenerator) {
            PromptGeneratorView(template: template, context: modelContext)
        }
        .sheet(isPresented: $showPlaceholderPicker) {
            PlaceholderPickerSheet(
                placeholders: allPlaceholders,
                onSelect: { placeholder in
                    insertPlaceholderKey(placeholder.key, into: $bindableViewModel.editContent)
                    showPlaceholderPicker = false
                }
            )
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helper Methods

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    /// Fügt einen Platzhalter-Key an der aktuellen Position ein
    private func insertPlaceholderKey(_ key: String, into binding: Binding<String>) {
        // Füge Platzhalter mit Key ein
        binding.wrappedValue += "{{\(key)}}"
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
