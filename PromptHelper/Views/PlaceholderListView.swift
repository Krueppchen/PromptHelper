//
//  PlaceholderListView.swift
//  PromptHelper
//
//  Created by Claude Code on 2025-11-14.
//

import SwiftUI
import SwiftData

/// Liste aller Platzhalter-Definitionen
struct PlaceholderListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: PlaceholderListViewModel?

    /// Query für alle Platzhalter
    @Query(sort: \PlaceholderDefinition.label) private var allPlaceholders: [PlaceholderDefinition]

    /// Navigation-State
    @State private var selectedPlaceholder: PlaceholderDefinition?

    init() {
        // ViewModel will be initialized in onAppear with the correct context
    }

    var body: some View {
        Group {
            if let viewModel = viewModel {
                placeholderListContent(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Platzhalter")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    withAnimation(DesignSystem.Animation.smooth) {
                        createNewPlaceholder()
                    }
                } label: {
                    Label("Neu", systemImage: "plus.circle.fill")
                }
            }
        }
        .onAppear {
            // Update viewModel with the correct context
            if viewModel == nil || viewModel?.context !== modelContext {
                viewModel = PlaceholderListViewModel(context: modelContext)
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func placeholderListContent(viewModel: PlaceholderListViewModel) -> some View {
        @Bindable var bindableViewModel = viewModel

        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.md) {
                // Search and Filter Bar
                searchAndFilterBar(viewModel: bindableViewModel)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.top, DesignSystem.Spacing.sm)

                // Placeholders List
                let filteredPlaceholders = filterPlaceholders(allPlaceholders, viewModel: viewModel)
                if filteredPlaceholders.isEmpty {
                    ModernEmptyState(
                        icon: "curlybraces",
                        title: "Keine Platzhalter gefunden",
                        message: "Erstellen Sie einen neuen Platzhalter mit dem + Button",
                        action: createNewPlaceholder,
                        actionLabel: "Neuer Platzhalter"
                    )
                    .padding(.top, DesignSystem.Spacing.xxl)
                } else {
                    placeholdersGrid(filteredPlaceholders)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                }
            }
            .padding(.bottom, DesignSystem.Spacing.lg)
        }
        .background(DesignSystem.SemanticColor.background)
        .navigationDestination(item: $selectedPlaceholder) { placeholder in
            PlaceholderEditorView(placeholder: placeholder)
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
    }

    // MARK: - Subviews for List Content

    private func searchAndFilterBar(viewModel: PlaceholderListViewModel) -> some View {
        @Bindable var bindableViewModel = viewModel

        return ModernCard(padding: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: DesignSystem.IconSize.sm))
                    .foregroundStyle(DesignSystem.SemanticColor.tertiary)

                TextField("Suchen...", text: $bindableViewModel.searchText)
                    .font(DesignSystem.Typography.body)
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(DesignSystem.SemanticColor.tertiaryBackground)
            .cornerRadius(DesignSystem.CornerRadius.sm)
        }
    }

    private func placeholdersGrid(_ placeholders: [PlaceholderDefinition]) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            ForEach(placeholders) { placeholder in
                ModernPlaceholderCard(placeholder: placeholder)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedPlaceholder = placeholder
                    }
                    .contextMenu {
                        Button {
                            let duplicate = viewModel?.duplicatePlaceholder(placeholder)
                            selectedPlaceholder = duplicate
                        } label: {
                            Label("Duplizieren", systemImage: "doc.on.doc")
                        }

                        Button(role: .destructive) {
                            viewModel?.deletePlaceholder(placeholder)
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                    }
            }
        }
    }

    // MARK: - Helper Methods

    private func filterPlaceholders(_ placeholders: [PlaceholderDefinition], viewModel: PlaceholderListViewModel) -> [PlaceholderDefinition] {
        placeholders.filter { placeholder in
            // Such-Filter
            if !viewModel.searchText.isEmpty {
                let searchLower = viewModel.searchText.lowercased()
                let matchesKey = placeholder.key.lowercased().contains(searchLower)
                let matchesLabel = placeholder.label.lowercased().contains(searchLower)

                return matchesKey || matchesLabel
            }

            return true
        }
    }

    private func createNewPlaceholder() {
        guard let viewModel = viewModel else { return }
        let newPlaceholder = viewModel.createPlaceholder()
        selectedPlaceholder = newPlaceholder
    }
}

// MARK: - Modern Placeholder Card

/// Vereinfachte Card-View für einen Platzhalter - minimalistisch und klar
struct ModernPlaceholderCard: View {
    let placeholder: PlaceholderDefinition

    var body: some View {
        VStack(spacing: 16) {
            // Großes Icon
            Image(systemName: placeholder.type.iconName)
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: .infinity)
                .padding(.top, 20)

            VStack(spacing: 6) {
                // Label
                Text(placeholder.label)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                // Key subtil
                Text("{{\(placeholder.key)}}")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)

                // Typ
                Text(placeholder.type.displayName)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(4)
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        PlaceholderListView()
    }
    .modelContainer(PersistenceController.preview.container)
}
