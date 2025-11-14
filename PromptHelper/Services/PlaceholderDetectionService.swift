//
//  PlaceholderDetectionService.swift
//  PromptHelper
//
//  Created by Claude Code on 2025-11-14.
//

import Foundation
import SwiftData

/// Service für das Erkennen und Verwalten von Platzhaltern in Templates
final class PlaceholderDetectionService {

    // MARK: - Public Methods

    /// Erkennt alle Platzhalter-Keys im Template-Content
    /// - Parameter template: Das zu analysierende Template
    /// - Returns: Array von eindeutigen Platzhalter-Keys
    func detectPlaceholderKeys(in template: PromptTemplate) -> [String] {
        let keys = template.content.extractPlaceholderKeys()
        return Array(Set(keys)).sorted() // Duplikate entfernen und sortieren
    }

    /// Synchronisiert die Platzhalter eines Templates mit dem Content
    /// Erstellt fehlende Zuordnungen und entfernt nicht mehr verwendete
    /// - Parameters:
    ///   - template: Das Template
    ///   - context: Der ModelContext für Datenbank-Operationen
    ///   - globalPlaceholders: Array von globalen Platzhalter-Definitionen
    @MainActor
    func syncPlaceholders(
        for template: PromptTemplate,
        context: ModelContext,
        globalPlaceholders: [PlaceholderDefinition]
    ) {
        let detectedKeys = detectPlaceholderKeys(in: template)
        let existingPlaceholders = template.placeholders ?? []

        // Finde Platzhalter, die im Content vorkommen, aber noch keine Zuordnung haben
        let existingKeys = Set(existingPlaceholders.compactMap { $0.placeholder?.key })
        let missingKeys = detectedKeys.filter { !existingKeys.contains($0) }

        // Erstelle Zuordnungen für fehlende Platzhalter
        for key in missingKeys {
            // Versuche, einen globalen Platzhalter zu finden
            if let globalPlaceholder = globalPlaceholders.first(where: { $0.key == key }) {
                let association = PromptTemplatePlaceholder(
                    template: template,
                    placeholder: globalPlaceholder,
                    isRequired: true,
                    sortOrder: (existingPlaceholders.count)
                )
                context.insert(association)
            }
            // Wenn kein globaler Platzhalter existiert, erstelle eine lokale Definition
            else {
                let newPlaceholder = PlaceholderDefinition(
                    key: key,
                    label: key.capitalized, // Default: Key als Label
                    type: .text,
                    isGlobal: false
                )
                context.insert(newPlaceholder)

                let association = PromptTemplatePlaceholder(
                    template: template,
                    placeholder: newPlaceholder,
                    isRequired: true,
                    sortOrder: (existingPlaceholders.count)
                )
                context.insert(association)
            }
        }

        // Entferne Zuordnungen für Platzhalter, die nicht mehr im Content vorkommen
        let keysToRemove = existingKeys.subtracting(Set(detectedKeys))
        for placeholderAssociation in existingPlaceholders {
            if let key = placeholderAssociation.placeholder?.key, keysToRemove.contains(key) {
                context.delete(placeholderAssociation)
            }
        }
    }

    /// Findet fehlende Platzhalter-Definitionen für ein Template
    /// - Parameters:
    ///   - template: Das Template
    ///   - globalPlaceholders: Array von globalen Platzhalter-Definitionen
    /// - Returns: Array von Keys, für die keine Definition existiert
    func findMissingDefinitions(
        for template: PromptTemplate,
        globalPlaceholders: [PlaceholderDefinition]
    ) -> [String] {
        let detectedKeys = detectPlaceholderKeys(in: template)
        let definedKeys = Set(globalPlaceholders.map { $0.key })
        let templatePlaceholderKeys = Set((template.placeholders ?? []).compactMap { $0.placeholder?.key })

        let allDefinedKeys = definedKeys.union(templatePlaceholderKeys)
        return detectedKeys.filter { !allDefinedKeys.contains($0) }
    }

    /// Validiert, ob ein Platzhalter-Key gültig ist
    /// - Parameter key: Der zu validierende Key
    /// - Returns: true wenn gültig, false sonst
    func isValidPlaceholderKey(_ key: String) -> Bool {
        return key.isValidPlaceholderKey()
    }

    /// Schlägt einen gültigen Platzhalter-Key basierend auf einem Label vor
    /// - Parameter label: Das Label
    /// - Returns: Ein gültiger Key-Vorschlag
    func suggestKey(from label: String) -> String {
        // Konvertiere zu lowercase und ersetze Leerzeichen durch Underscores
        let key = label
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "ä", with: "ae")
            .replacingOccurrences(of: "ö", with: "oe")
            .replacingOccurrences(of: "ü", with: "ue")
            .replacingOccurrences(of: "ß", with: "ss")

        // Entferne ungültige Zeichen
        let validCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-"))
        let filtered = key.unicodeScalars.filter { validCharacters.contains($0) }
        return String(String.UnicodeScalarView(filtered))
    }
}
