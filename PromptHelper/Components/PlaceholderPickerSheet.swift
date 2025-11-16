//
//  PlaceholderPickerSheet.swift
//  PromptHelper
//
//  Created by Claude Code on 2025-11-16.
//

import SwiftUI
import SwiftData

/// Sheet zum Auswählen eines Platzhalters
struct PlaceholderPickerSheet: View {
    let placeholders: [PlaceholderDefinition]
    let onSelect: (PlaceholderDefinition) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedTags: Set<String> = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Suchleiste
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)

                    TextField("Suchen...", text: $searchText)
                        .font(.body)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // Tag-Filter (wenn Tags vorhanden)
                let availableTags = getAllTags()
                if !availableTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(availableTags, id: \.self) { tag in
                                let isSelected = selectedTags.contains(tag)
                                Button {
                                    if isSelected {
                                        selectedTags.remove(tag)
                                    } else {
                                        selectedTags.insert(tag)
                                    }
                                } label: {
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(isSelected ? Color.accentColor : Color.accentColor.opacity(0.15))
                                        .foregroundStyle(isSelected ? .white : .accentColor)
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 8)

                    if !selectedTags.isEmpty {
                        HStack {
                            Spacer()
                            Button {
                                selectedTags.removeAll()
                            } label: {
                                Text("Zurücksetzen")
                                    .font(.caption)
                                    .foregroundStyle(.accentColor)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    }
                }

                Divider()

                // Platzhalter-Liste
                let filteredPlaceholders = filterPlaceholders()
                if filteredPlaceholders.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "curlybraces")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("Keine Platzhalter gefunden")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredPlaceholders) { placeholder in
                                PlaceholderPickerRow(placeholder: placeholder)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        onSelect(placeholder)
                                    }
                                Divider()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Platzhalter wählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func getAllTags() -> [String] {
        var allTags = Set<String>()
        for placeholder in placeholders {
            allTags.formUnion(placeholder.tags)
        }
        return allTags.sorted()
    }

    private func filterPlaceholders() -> [PlaceholderDefinition] {
        placeholders.filter { placeholder in
            // Tag-Filter
            if !selectedTags.isEmpty {
                let hasSelectedTag = selectedTags.contains { tag in
                    placeholder.tags.contains(tag)
                }
                guard hasSelectedTag else { return false }
            }

            // Such-Filter
            if !searchText.isEmpty {
                let searchLower = searchText.lowercased()
                let matchesKey = placeholder.key.lowercased().contains(searchLower)
                let matchesLabel = placeholder.label.lowercased().contains(searchLower)

                return matchesKey || matchesLabel
            }

            return true
        }
    }
}

// MARK: - Placeholder Picker Row

/// Eine Zeile im Platzhalter-Picker
struct PlaceholderPickerRow: View {
    let placeholder: PlaceholderDefinition

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: placeholder.type.iconName)
                .font(.system(size: 24))
                .foregroundStyle(Color.accentColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                // Label
                Text(placeholder.label)
                    .font(.body.weight(.medium))

                // Key
                Text("{{\(placeholder.key)}}")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)

                // Tags
                if !placeholder.tags.isEmpty {
                    TagFlowLayout(spacing: 4) {
                        ForEach(placeholder.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.15))
                                .foregroundStyle(.accentColor)
                                .cornerRadius(6)
                        }
                    }
                    .padding(.top, 4)
                }
            }

            Spacer()

            // Typ-Badge
            Text(placeholder.type.displayName)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                .cornerRadius(6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Previews

#Preview {
    if let placeholders = try? PersistenceController.preview.mainContext.fetch(
        FetchDescriptor<PlaceholderDefinition>()
    ) {
        PlaceholderPickerSheet(placeholders: placeholders) { placeholder in
            print("Selected: \(placeholder.key)")
        }
        .modelContainer(PersistenceController.preview.container)
    }
}
