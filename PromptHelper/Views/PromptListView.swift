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
    @State private var viewModel: PromptListViewModel?

    /// Query für alle Templates
    @Query(sort: \PromptTemplate.updatedAt, order: .reverse) private var allTemplates: [PromptTemplate]

    /// Navigation-State
    @State private var selectedTemplate: PromptTemplate?
    @State private var isCreatingNew = false
    @State private var showTagFilter = false

    var body: some View {
        Group {
            if let viewModel = viewModel {
                templateListContent(viewModel: viewModel)
            } else {
                ProgressView()
                    .onAppear {
                        viewModel = PromptListViewModel(context: modelContext)
                    }
            }
        }
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
    }

    // MARK: - Subviews

    @ViewBuilder
    private func templateListContent(viewModel: PromptListViewModel) -> some View {
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
                let filteredTemplates = filterTemplates(allTemplates, with: viewModel)

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

    private func filterTemplates(_ templates: [PromptTemplate], with viewModel: PromptListViewModel) -> [PromptTemplate] {
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
        guard let viewModel = viewModel else { return }
        let newTemplate = viewModel.createTemplate()
        selectedTemplate = newTemplate
    }
}

// MARK: - Template Row View

/// Zeilen-View für ein Template
struct TemplateRowView: View {
    let template: PromptTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(template.title)
                    .font(.headline)

                Spacer()

                if template.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                }
            }

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
                        ForEach(template.tags, id: \.self) { tag in
                            TagChipView(tag: tag, isSelected: false) { }
                        }
                    }
                }
            }

            // Metadaten
            HStack {
                Label(
                    template.updatedAt.formatted(date: .abbreviated, time: .shortened),
                    systemImage: "clock"
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Spacer()

                if let placeholderCount = template.placeholders?.count, placeholderCount > 0 {
                    Label("\(placeholderCount)", systemImage: "curlybraces")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        PromptListView()
    }
    .modelContainer(PersistenceController.preview.container)
}
