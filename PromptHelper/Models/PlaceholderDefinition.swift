//
//  PlaceholderDefinition.swift
//  PromptHelper
//
//  Created by Claude Code on 2025-11-14.
//

import Foundation
import SwiftData

/// Definition eines Platzhalters
/// Beschreibt die Eigenschaften und das Verhalten eines Platzhalters
@Model
final class PlaceholderDefinition {
    /// Eindeutige ID
    var id: UUID

    /// Technischer Schlüssel (z.B. "zielgruppe")
    /// Wird im Template-Content als {{key}} verwendet
    var key: String

    /// Menschenlesbares Label für die UI (z.B. "Zielgruppe")
    var label: String

    /// Typ des Platzhalters (bestimmt UI-Darstellung)
    var typeRaw: String

    /// Liste möglicher Werte für Choice-Typen
    var options: [String]

    /// True = global verfügbar, False = nur für spezifische Templates
    var isGlobal: Bool

    /// True = Pflichtfeld, muss ausgefüllt werden
    var isRequired: Bool

    /// Optionaler Standardwert
    var defaultValue: String?

    /// Optionale Beschreibung/Hilfetext
    var descriptionText: String?

    /// Tags für Kategorisierung und Filterung
    var tags: [String] = []

    /// Erstellungsdatum
    var createdAt: Date

    /// Letztes Änderungsdatum
    var updatedAt: Date

    // MARK: - Computed Properties

    /// Typsichere Zugriff auf den Platzhalter-Typ
    var type: PlaceholderType {
        get {
            PlaceholderType(rawValue: typeRaw) ?? .text
        }
        set {
            typeRaw = newValue.rawValue
        }
    }

    // MARK: - Initialisierung

    init(
        id: UUID = UUID(),
        key: String,
        label: String,
        type: PlaceholderType = .text,
        options: [String] = [],
        isGlobal: Bool = true,
        isRequired: Bool = false,
        defaultValue: String? = nil,
        descriptionText: String? = nil,
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.key = key
        self.label = label
        self.typeRaw = type.rawValue
        self.options = options
        self.isGlobal = isGlobal
        self.isRequired = isRequired
        self.defaultValue = defaultValue
        self.descriptionText = descriptionText
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Validation

    /// Validiert, ob die Platzhalter-Definition korrekt ist
    func validate() -> Result<Void, ValidationError> {
        // Key darf nicht leer sein
        guard !key.trimmingCharacters(in: .whitespaces).isEmpty else {
            return .failure(.emptyKey)
        }

        // Key darf keine Leerzeichen enthalten
        guard !key.contains(" ") else {
            return .failure(.keyContainsSpaces)
        }

        // Label darf nicht leer sein
        guard !label.trimmingCharacters(in: .whitespaces).isEmpty else {
            return .failure(.emptyLabel)
        }

        // Choice-Typen benötigen Optionen
        if type.requiresOptions && options.isEmpty {
            return .failure(.missingOptions)
        }

        return .success(())
    }

    enum ValidationError: LocalizedError {
        case emptyKey
        case keyContainsSpaces
        case emptyLabel
        case missingOptions

        var errorDescription: String? {
            switch self {
            case .emptyKey:
                return "Der Platzhalter-Schlüssel darf nicht leer sein."
            case .keyContainsSpaces:
                return "Der Platzhalter-Schlüssel darf keine Leerzeichen enthalten."
            case .emptyLabel:
                return "Das Label darf nicht leer sein."
            case .missingOptions:
                return "Für Auswahl-Platzhalter müssen Optionen angegeben werden."
            }
        }
    }
}
