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
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        createNewTemplate()
                    } label: {
                        Label("Neu", systemImage: "plus")
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
        List {
            // Filter-Sektion
            Section {
                HStack {
                    TextField("Suchen...", text: $viewModel.searchText)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        viewModel.showFavoritesOnly.toggle()
                    } label: {
                        Image(systemName: viewModel.showFavoritesOnly ? "star.fill" : "star")
                            .foregroundStyle(viewModel.showFavoritesOnly ? .yellow : .gray)
                    }
                }
            }

            // Tag-Filter
            let availableTags = viewModel.getAllTags(from: allTemplates)
            if !availableTags.isEmpty {
                Section("Tags") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(availableTags, id: \.self) { tag in
                                TagChipView(
                                    tag: tag,
                                    isSelected: viewModel.selectedTag == tag
                                ) {
                                    if viewModel.selectedTag == tag {
                                        viewModel.selectedTag = nil
                                    } else {
                                        viewModel.selectedTag = tag
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            // Template-Liste
            Section("Templates") {
                let filteredTemplates = filterTemplates(allTemplates)

                if filteredTemplates.isEmpty {
                    ContentUnavailableView(
                        "Keine Templates gefunden",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Erstellen Sie ein neues Template mit dem + Button")
                    )
                } else {
                    ForEach(filteredTemplates) { template in
                        TemplateRowView(template: template)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedTemplate = template
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    viewModel.toggleFavorite(template)
                                } label: {
                                    Label("Favorit", systemImage: template.isFavorite ? "star.fill" : "star")
                                }
                                .tint(.yellow)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.deleteTemplate(template)
                                } label: {
                                    Label("Löschen", systemImage: "trash")
                                }

                                Button {
                                    let duplicate = viewModel.duplicateTemplate(template)
                                    selectedTemplate = duplicate
                                } label: {
                                    Label("Duplizieren", systemImage: "doc.on.doc")
                                }
                                .tint(.blue)
                            }
                    }
                }
            }
        }
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

// MARK: - Template Row View

/// Zeilen-View für ein Template
struct TemplateRowView: View {
    let template: PromptTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Icon Badge
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(template.isFavorite ? Color.yellow.opacity(0.2) : Color.accentColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: template.isFavorite ? "star.fill" : "doc.text")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(template.isFavorite ? .yellow : .accentColor)
                }

                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(template.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if let description = template.descriptionText, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    // Tags
                    if !template.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(template.tags.prefix(3), id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.accentColor.opacity(0.15))
                                        .foregroundStyle(.accentColor)
                                        .clipShape(Capsule())
                                }
                                if template.tags.count > 3 {
                                    Text("+\(template.tags.count - 3)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 4)
                                }
                            }
                        }
                    }

                    // Metadaten
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text(template.updatedAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)

                        if let placeholderCount = template.placeholders?.count, placeholderCount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "curlybraces")
                                    .font(.caption2)
                                Text("\(placeholderCount)")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        PromptListView()
    }
    .modelContainer(PersistenceController.preview.container)
}
