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
        LazyVStack(spacing: DesignSystem.Spacing.md) {
            ForEach(placeholders) { placeholder in
                ModernPlaceholderCard(placeholder: placeholder)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(DesignSystem.Animation.smooth) {
                            selectedPlaceholder = placeholder
                        }
                    }
                    .contextMenu {
                        Button {
                            let duplicate = viewModel?.duplicatePlaceholder(placeholder)
                            selectedPlaceholder = duplicate
                        } label: {
                            Label("Duplizieren", systemImage: "doc.on.doc")
                        }

                        Divider()

                        Button(role: .destructive) {
                            withAnimation(DesignSystem.Animation.smooth) {
                                viewModel?.deletePlaceholder(placeholder)
                            }
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
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

/// Moderne Card-View für einen Platzhalter
struct ModernPlaceholderCard: View {
    let placeholder: PlaceholderDefinition

    var body: some View {
        ModernCard(padding: DesignSystem.Spacing.md) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                // Header mit Icon und Global-Badge
                HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
                    ModernIconBadge(
                        icon: placeholder.type.iconName,
                        size: 52,
                        iconSize: DesignSystem.IconSize.lg,
                        backgroundColor: DesignSystem.SemanticColor.accent.opacity(0.15),
                        foregroundColor: DesignSystem.SemanticColor.accent
                    )

                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text(placeholder.label)
                            .font(DesignSystem.Typography.title3)
                            .foregroundStyle(DesignSystem.SemanticColor.primary)
                            .lineLimit(1)

                        Text("{{\(placeholder.key)}}")
                            .font(DesignSystem.Typography.bodyMonospaced)
                            .foregroundStyle(DesignSystem.SemanticColor.secondary)
                            .padding(.horizontal, DesignSystem.Spacing.sm)
                            .padding(.vertical, DesignSystem.Spacing.xxs)
                            .background(DesignSystem.SemanticColor.tertiaryBackground)
                            .cornerRadius(DesignSystem.CornerRadius.sm)
                    }
                }

                // Description
                if let description = placeholder.descriptionText, !description.isEmpty {
                    Text(description)
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(DesignSystem.SemanticColor.secondary)
                        .lineLimit(2)
                }

                // Type and Options
                HStack(spacing: DesignSystem.Spacing.xs) {
                    ModernBadge(text: placeholder.type.displayName, style: .accent)

                    if placeholder.type.requiresOptions && !placeholder.options.isEmpty {
                        ModernBadge(
                            text: "\(placeholder.options.count) Optionen",
                            icon: "list.bullet",
                            style: .default
                        )
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: DesignSystem.IconSize.xs, weight: .semibold))
                        .foregroundStyle(DesignSystem.SemanticColor.tertiary)
                }

                // Options Preview
                if placeholder.type.requiresOptions && !placeholder.options.isEmpty {
                    Divider()
                        .padding(.vertical, DesignSystem.Spacing.xxs)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            ForEach(placeholder.options.prefix(5), id: \.self) { option in
                                Text(option)
                                    .font(DesignSystem.Typography.caption2)
                                    .padding(.horizontal, DesignSystem.Spacing.sm)
                                    .padding(.vertical, DesignSystem.Spacing.xxs)
                                    .background(DesignSystem.SemanticColor.secondaryBackground)
                                    .foregroundStyle(DesignSystem.SemanticColor.secondary)
                                    .cornerRadius(DesignSystem.CornerRadius.sm)
                            }
                            if placeholder.options.count > 5 {
                                Text("+\(placeholder.options.count - 5) mehr")
                                    .font(DesignSystem.Typography.caption2)
                                    .foregroundStyle(DesignSystem.SemanticColor.tertiary)
                            }
                        }
                    }
                }
            }
        }
    }
}

extension PlaceholderType {
    var iconName: String {
        switch self {
        case .text: return "textformat"
        case .number: return "number"
        case .date: return "calendar"
        case .singleChoice: return "list.bullet.circle"
        case .multiChoice: return "checklist"
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        PlaceholderListView()
    }
    .modelContainer(PersistenceController.preview.container)
}
