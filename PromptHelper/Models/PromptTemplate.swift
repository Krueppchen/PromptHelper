//
//  PromptTemplate.swift
//  PromptHelper
//
//  Created by Claude Code on 2025-11-14.
//

import Foundation
import SwiftData

/// Prompt-Vorlage mit Platzhaltern
/// Enthält den Template-Text und zugeordnete Platzhalter-Definitionen
@Model
final class PromptTemplate {
    /// Eindeutige ID
    var id: UUID

    /// Titel der Vorlage
    var title: String

    /// Optionale Beschreibung
    var descriptionText: String?

    /// Der eigentliche Prompt-Text mit Platzhaltern im Format {{key}}
    var content: String

    /// Tags für Kategorisierung und Suche
    var tags: [String]

    /// Favoriten-Status
    var isFavorite: Bool

    /// Erstellungsdatum
    var createdAt: Date

    /// Letztes Änderungsdatum
    var updatedAt: Date

    /// Beziehung zu Platzhalter-Zuordnungen
    /// Verwendet @Relationship für SwiftData-Relationen
    @Relationship(deleteRule: .cascade, inverse: \PromptTemplatePlaceholder.template)
    var placeholders: [PromptTemplatePlaceholder]?

    // MARK: - Initialisierung

    init(
        id: UUID = UUID(),
        title: String,
        descriptionText: String? = nil,
        content: String = "",
        tags: [String] = [],
        isFavorite: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.descriptionText = descriptionText
        self.content = content
        self.tags = tags
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.placeholders = []
    }

    // MARK: - Helper Methods

    /// Gibt alle Platzhalter-Keys zurück, die im Content vorkommen
    func extractPlaceholderKeys() -> [String] {
        let pattern = "\\{\\{([^}]+)\\}\\}"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }

        let nsString = content as NSString
        let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: nsString.length))

        return matches.compactMap { match in
            guard match.numberOfRanges >= 2 else { return nil }
            let range = match.range(at: 1)
            return nsString.substring(with: range).trimmingCharacters(in: .whitespaces)
        }
    }

    /// Prüft, ob der Template gültig ist
    func validate() -> Result<Void, ValidationError> {
        // Titel darf nicht leer sein
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            return .failure(.emptyTitle)
        }

        return .success(())
    }

    enum ValidationError: LocalizedError {
        case emptyTitle

        var errorDescription: String? {
            switch self {
            case .emptyTitle:
                return "Der Titel darf nicht leer sein."
            }
        }
    }

    /// Aktualisiert das updatedAt-Datum
    func markAsUpdated() {
        self.updatedAt = Date()
    }
}
