//
//  PromptListViewModel.swift
//  PromptHelper
//
//  Created by Claude Code on 2025-11-14.
//

import Foundation
import SwiftData
import SwiftUI

/// ViewModel für die Prompt-Liste
@MainActor
@Observable
final class PromptListViewModel {
    /// Suchbegriff für die Filterung
    var searchText: String = ""

    /// Filter: Nur Favoriten anzeigen
    var showFavoritesOnly: Bool = false

    /// Ausgewählter Tag-Filter
    var selectedTag: String?

    /// Fehlermeldung
    var errorMessage: String?

    /// ModelContext für Datenbank-Operationen
    private let context: ModelContext

    // MARK: - Initialisierung

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Public Methods

    /// Erstellt ein neues Template
    func createTemplate() -> PromptTemplate {
        let template = PromptTemplate(
            title: "Neues Template",
            content: ""
        )
        context.insert(template)
        saveContext()
        return template
    }

    /// Dupliziert ein Template
    /// - Parameter template: Das zu duplizierende Template
    /// - Returns: Das neue Template
    func duplicateTemplate(_ template: PromptTemplate) -> PromptTemplate {
        let duplicate = PromptTemplate(
            title: "\(template.title) (Kopie)",
            descriptionText: template.descriptionText,
            content: template.content,
            tags: template.tags,
            isFavorite: false
        )
        context.insert(duplicate)

        // Kopiere auch die Platzhalter-Zuordnungen
        if let placeholders = template.placeholders {
            for placeholder in placeholders {
                let duplicatePlaceholder = PromptTemplatePlaceholder(
                    template: duplicate,
                    placeholder: placeholder.placeholder,
                    isRequired: placeholder.isRequired,
                    sortOrder: placeholder.sortOrder,
                    templateSpecificDefaultValue: placeholder.templateSpecificDefaultValue
                )
                context.insert(duplicatePlaceholder)
            }
        }

        saveContext()
        return duplicate
    }

    /// Löscht ein Template
    /// - Parameter template: Das zu löschende Template
    func deleteTemplate(_ template: PromptTemplate) {
        context.delete(template)
        saveContext()
    }

    /// Togglet den Favoriten-Status eines Templates
    /// - Parameter template: Das Template
    func toggleFavorite(_ template: PromptTemplate) {
        template.isFavorite.toggle()
        template.markAsUpdated()
        saveContext()
    }

    /// Gibt alle eindeutigen Tags zurück
    /// - Parameter templates: Array von Templates
    /// - Returns: Sortiertes Array von eindeutigen Tags
    func getAllTags(from templates: [PromptTemplate]) -> [String] {
        let allTags = templates.flatMap { $0.tags }
        return Array(Set(allTags)).sorted()
    }

    // MARK: - Private Methods

    /// Speichert den Context
    private func saveContext() {
        do {
            try context.save()
        } catch {
            errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
        }
    }
}
