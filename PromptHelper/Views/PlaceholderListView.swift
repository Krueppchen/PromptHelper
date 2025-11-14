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
    @State private var viewModel: PlaceholderListViewModel

    /// Query für alle Platzhalter
    @Query(sort: \PlaceholderDefinition.label) private var allPlaceholders: [PlaceholderDefinition]

    /// Navigation-State
    @State private var selectedPlaceholder: PlaceholderDefinition?

    init() {
        // Initialize viewModel with a temporary context
        // It will be properly set in onAppear
        let tempContext = ModelContext(PersistenceController.shared.container)
        _viewModel = State(initialValue: PlaceholderListViewModel(context: tempContext))
    }

    var body: some View {
        placeholderListContent
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
            .onAppear {
                // Update viewModel with the correct context
                if viewModel.context !== modelContext {
                    viewModel = PlaceholderListViewModel(context: modelContext)
                }
            }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var placeholderListContent: some View {
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
                let filteredPlaceholders = filterPlaceholders(allPlaceholders)

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

    private func filterPlaceholders(_ placeholders: [PlaceholderDefinition]) -> [PlaceholderDefinition] {
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
        let newPlaceholder = viewModel.createPlaceholder()
        selectedPlaceholder = newPlaceholder
    }
}

// MARK: - Placeholder Row View

/// Zeilen-View für einen Platzhalter
struct PlaceholderRowView: View {
    let placeholder: PlaceholderDefinition

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Icon Badge
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: placeholder.type.iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.accentColor)
                }

                // Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(placeholder.label)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Spacer()

                        if placeholder.isGlobal {
                            Image(systemName: "globe")
                                .font(.caption)
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }

                    Text("{{\(placeholder.key)}}")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    if let description = placeholder.descriptionText, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .padding(.top, 2)
                    }

                    // Type Badge
                    HStack(spacing: 8) {
                        Text(placeholder.type.displayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())

                        if placeholder.type.requiresOptions && !placeholder.options.isEmpty {
                            Text("\(placeholder.options.count) Optionen")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Options Preview
            if placeholder.type.requiresOptions && !placeholder.options.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(placeholder.options.prefix(5), id: \.self) { option in
                            Text(option)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        if placeholder.options.count > 5 {
                            Text("+\(placeholder.options.count - 5) mehr")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
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
