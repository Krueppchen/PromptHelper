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

    var body: some View {
        Group {
            if let viewModel = viewModel {
                placeholderListContent(viewModel: viewModel)
            } else {
                ProgressView()
                    .onAppear {
                        viewModel = PlaceholderListViewModel(context: modelContext)
                    }
            }
        }
        .navigationTitle("Platzhalter")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    createNewPlaceholder()
                } label: {
                    Label("Neu", systemImage: "plus")
                }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func placeholderListContent(viewModel: PlaceholderListViewModel) -> some View {
        List {
            // Filter-Sektion
            Section {
                HStack {
                    TextField("Suchen...", text: $viewModel.searchText)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        viewModel.showGlobalOnly.toggle()
                    } label: {
                        Image(systemName: viewModel.showGlobalOnly ? "globe" : "doc.text")
                            .foregroundStyle(viewModel.showGlobalOnly ? .blue : .gray)
                    }
                }
            }

            // Platzhalter-Liste
            Section("Definitionen") {
                let filteredPlaceholders = filterPlaceholders(allPlaceholders, with: viewModel)

                if filteredPlaceholders.isEmpty {
                    ContentUnavailableView(
                        "Keine Platzhalter gefunden",
                        systemImage: "curlybraces",
                        description: Text("Erstellen Sie einen neuen Platzhalter mit dem + Button")
                    )
                } else {
                    ForEach(filteredPlaceholders) { placeholder in
                        PlaceholderRowView(placeholder: placeholder)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedPlaceholder = placeholder
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.deletePlaceholder(placeholder)
                                } label: {
                                    Label("Löschen", systemImage: "trash")
                                }

                                Button {
                                    let duplicate = viewModel.duplicatePlaceholder(placeholder)
                                    selectedPlaceholder = duplicate
                                } label: {
                                    Label("Duplizieren", systemImage: "doc.on.doc")
                                }
                                .tint(.blue)
                            }
                    }
                }
            }
        }
        .navigationDestination(item: $selectedPlaceholder) { placeholder in
            PlaceholderEditorView(placeholder: placeholder)
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

    private func filterPlaceholders(
        _ placeholders: [PlaceholderDefinition],
        with viewModel: PlaceholderListViewModel
    ) -> [PlaceholderDefinition] {
        placeholders.filter { placeholder in
            // Global-Filter
            if viewModel.showGlobalOnly && !placeholder.isGlobal {
                return false
            }

            // Such-Filter
            if !viewModel.searchText.isEmpty {
                let searchLower = viewModel.searchText.lowercased()
                let matchesKey = placeholder.key.lowercased().contains(searchLower)
                let matchesLabel = placeholder.label.lowercased().contains(searchLower)

                if !matchesKey && !matchesLabel {
                    return false
                }
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

// MARK: - Placeholder Row View

/// Zeilen-View für einen Platzhalter
struct PlaceholderRowView: View {
    let placeholder: PlaceholderDefinition

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(placeholder.label)
                        .font(.headline)

                    Text("{{\(placeholder.key)}}")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(placeholder.type.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.2))
                        .clipShape(Capsule())

                    if placeholder.isGlobal {
                        Label("Global", systemImage: "globe")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }
            }

            if let description = placeholder.descriptionText, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if placeholder.type.requiresOptions && !placeholder.options.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(placeholder.options.prefix(5), id: \.self) { option in
                            Text(option)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(Capsule())
                        }
                        if placeholder.options.count > 5 {
                            Text("+\(placeholder.options.count - 5)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        PlaceholderListView()
    }
    .modelContainer(PersistenceController.preview.container)
}
