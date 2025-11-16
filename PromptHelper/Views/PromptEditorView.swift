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

                // Großer Editor - im Vordergrund
                TextEditor(text: $bindableViewModel.editContent)
                    .font(.system(size: 17, design: .default))
                    .padding(20)
                    .scrollContentBackground(.hidden)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            HStack(spacing: 8) {
                                Button {
                                    insertPlaceholder(into: $bindableViewModel.editContent)
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
            PromptGeneratorView(template: template)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helper Methods

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

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
