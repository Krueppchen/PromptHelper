//
//  PromptListView.swift
//  PromptHelper
//
//  Created by Claude Code on 2025-11-14.
//

import SwiftUI
import SwiftData

/// Haupt-View für die Anzeige aller Prompt-Templates
struct PromptListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: PromptListViewModel

    /// Query für alle Templates
    @Query(sort: \PromptTemplate.updatedAt, order: .reverse) private var allTemplates: [PromptTemplate]

    /// Navigation-State
    @State private var selectedTemplate: PromptTemplate?
    @State private var isCreatingNew = false
    @State private var showTagFilter = false

    init() {
        // Initialize viewModel with a temporary context
        // It will be properly set in onAppear
        let tempContext = ModelContext(PersistenceController.shared.container)
        _viewModel = State(initialValue: PromptListViewModel(context: tempContext))
    }

    var body: some View {
        templateListContent
            .navigationTitle("Prompts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        withAnimation(DesignSystem.Animation.smooth) {
                            createNewTemplate()
                        }
                    } label: {
                        Label("Neu", systemImage: "plus.circle.fill")
                    }
                }
            }
            .onAppear {
                // Update viewModel with the correct context
                if viewModel.context !== modelContext {
                    viewModel = PromptListViewModel(context: modelContext)
                }
            }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var templateListContent: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.md) {
                // Search and Filter Bar
                searchAndFilterBar
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.top, DesignSystem.Spacing.sm)

                // Tag Filter
                let availableTags = viewModel.getAllTags(from: allTemplates)
                if !availableTags.isEmpty {
                    tagFilterSection(tags: availableTags)
                }

                // Templates Grid
                let filteredTemplates = filterTemplates(allTemplates)
                if filteredTemplates.isEmpty {
                    ModernEmptyState(
                        icon: "doc.text.magnifyingglass",
                        title: "Keine Templates gefunden",
                        message: "Erstellen Sie ein neues Template mit dem + Button",
                        action: createNewTemplate,
                        actionLabel: "Neues Template"
                    )
                    .padding(.top, DesignSystem.Spacing.xxl)
                } else {
                    templatesGrid(filteredTemplates)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                }
            }
            .padding(.bottom, DesignSystem.Spacing.lg)
        }
        .background(DesignSystem.SemanticColor.background)
        .navigationDestination(item: $selectedTemplate) { template in
            PromptEditorView(template: template)
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
    }

    // MARK: - Subviews for List Content

    private var searchAndFilterBar: some View {
        ModernCard(padding: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: DesignSystem.IconSize.sm))
                        .foregroundStyle(DesignSystem.SemanticColor.tertiary)

                    TextField("Suchen...", text: $viewModel.searchText)
                        .font(DesignSystem.Typography.body)
                }
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(DesignSystem.SemanticColor.tertiaryBackground)
                .cornerRadius(DesignSystem.CornerRadius.sm)

                Button {
                    withAnimation(DesignSystem.Animation.quick) {
                        viewModel.showFavoritesOnly.toggle()
                    }
                } label: {
                    Image(systemName: viewModel.showFavoritesOnly ? "star.fill" : "star")
                        .font(.system(size: DesignSystem.IconSize.md, weight: .medium))
                        .foregroundStyle(viewModel.showFavoritesOnly ? .yellow : DesignSystem.SemanticColor.secondary)
                        .frame(width: 40, height: 40)
                        .background(DesignSystem.SemanticColor.tertiaryBackground)
                        .cornerRadius(DesignSystem.CornerRadius.sm)
                }
            }
        }
    }

    private func tagFilterSection(tags: [String]) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Tags")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.SemanticColor.secondary)
                .padding(.horizontal, DesignSystem.Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(tags, id: \.self) { tag in
                        TagChipView(
                            tag: tag,
                            isSelected: viewModel.selectedTag == tag
                        ) {
                            withAnimation(DesignSystem.Animation.quick) {
                                if viewModel.selectedTag == tag {
                                    viewModel.selectedTag = nil
                                } else {
                                    viewModel.selectedTag = tag
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
        }
    }

    private func templatesGrid(_ templates: [PromptTemplate]) -> some View {
        LazyVStack(spacing: DesignSystem.Spacing.md) {
            ForEach(templates) { template in
                ModernTemplateCard(template: template)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(DesignSystem.Animation.smooth) {
                            selectedTemplate = template
                        }
                    }
                    .contextMenu {
                        Button {
                            viewModel.toggleFavorite(template)
                        } label: {
                            Label(
                                template.isFavorite ? "Favorit entfernen" : "Als Favorit markieren",
                                systemImage: template.isFavorite ? "star.slash" : "star.fill"
                            )
                        }

                        Button {
                            let duplicate = viewModel.duplicateTemplate(template)
                            selectedTemplate = duplicate
                        } label: {
                            Label("Duplizieren", systemImage: "doc.on.doc")
                        }

                        Divider()

                        Button(role: .destructive) {
                            withAnimation(DesignSystem.Animation.smooth) {
                                viewModel.deleteTemplate(template)
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

    private func filterTemplates(_ templates: [PromptTemplate]) -> [PromptTemplate] {
        templates.filter { template in
            // Favoriten-Filter
            if viewModel.showFavoritesOnly && !template.isFavorite {
                return false
            }

            // Tag-Filter
            if let selectedTag = viewModel.selectedTag {
                if !template.tags.contains(selectedTag) {
                    return false
                }
            }

            // Such-Filter
            if !viewModel.searchText.isEmpty {
                let searchLower = viewModel.searchText.lowercased()
                let matchesTitle = template.title.lowercased().contains(searchLower)
                let matchesDescription = template.descriptionText?.lowercased().contains(searchLower) ?? false
                let matchesTags = template.tags.contains { $0.lowercased().contains(searchLower) }

                if !matchesTitle && !matchesDescription && !matchesTags {
                    return false
                }
            }

            return true
        }
    }

    private func createNewTemplate() {
        let newTemplate = viewModel.createTemplate()
        selectedTemplate = newTemplate
    }
}

// MARK: - Modern Template Card

/// Moderne Card-View für ein Template
struct ModernTemplateCard: View {
    let template: PromptTemplate

    var body: some View {
        ModernCard(padding: DesignSystem.Spacing.md) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                // Header mit Icon und Favorit-Badge
                HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
                    ModernIconBadge(
                        icon: template.isFavorite ? "star.fill" : "doc.text.fill",
                        size: 52,
                        iconSize: DesignSystem.IconSize.lg,
                        backgroundColor: template.isFavorite ? Color.yellow.opacity(0.2) : DesignSystem.SemanticColor.accent.opacity(0.15),
                        foregroundColor: template.isFavorite ? .yellow : DesignSystem.SemanticColor.accent
                    )

                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text(template.title)
                            .font(DesignSystem.Typography.title3)
                            .foregroundStyle(DesignSystem.SemanticColor.primary)
                            .lineLimit(2)

                        if let description = template.descriptionText, !description.isEmpty {
                            Text(description)
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundStyle(DesignSystem.SemanticColor.secondary)
                                .lineLimit(2)
                        }
                    }

                    Spacer(minLength: 0)

                    if template.isFavorite {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: DesignSystem.IconSize.md))
                            .foregroundStyle(.yellow)
                            .symbolRenderingMode(.hierarchical)
                    }
                }

                // Tags
                if !template.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            ForEach(template.tags.prefix(5), id: \.self) { tag in
                                ModernBadge(text: tag, style: .accent)
                            }
                            if template.tags.count > 5 {
                                ModernBadge(text: "+\(template.tags.count - 5)", style: .default)
                            }
                        }
                    }
                }

                // Footer mit Metadaten
                HStack(spacing: DesignSystem.Spacing.md) {
                    Label(
                        template.updatedAt.formatted(date: .abbreviated, time: .omitted),
                        systemImage: "clock"
                    )
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.SemanticColor.tertiary)

                    if let placeholderCount = template.placeholders?.count, placeholderCount > 0 {
                        Label("\(placeholderCount)", systemImage: "curlybraces")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.SemanticColor.tertiary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: DesignSystem.IconSize.xs, weight: .semibold))
                        .foregroundStyle(DesignSystem.SemanticColor.tertiary)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        PromptListView()
    }
    .modelContainer(PersistenceController.preview.container)
}
