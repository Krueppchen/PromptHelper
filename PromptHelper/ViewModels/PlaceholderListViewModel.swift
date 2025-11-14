//
//  PlaceholderListViewModel.swift
//  PromptHelper
//
//  Created by Claude Code on 2025-11-14.
//

import Foundation
import SwiftData
import SwiftUI

/// ViewModel für die Platzhalter-Liste
@MainActor
@Observable
final class PlaceholderListViewModel {
    /// Suchbegriff für die Filterung
    var searchText: String = ""

    /// Filter: Nur globale Platzhalter anzeigen
    var showGlobalOnly: Bool = true

    /// Fehlermeldung
    var errorMessage: String?

    /// ModelContext für Datenbank-Operationen
    let context: ModelContext

    /// Service für Platzhalter-Verwaltung
    private let detectionService = PlaceholderDetectionService()

    // MARK: - Initialisierung

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Public Methods

    /// Erstellt einen neuen Platzhalter
    func createPlaceholder() -> PlaceholderDefinition {
        let placeholder = PlaceholderDefinition(
            key: "neuer_platzhalter",
            label: "Neuer Platzhalter",
            type: .text,
            isGlobal: true
        )
        context.insert(placeholder)
        saveContext()
        return placeholder
    }

    /// Löscht einen Platzhalter
    /// - Parameter placeholder: Der zu löschende Platzhalter
    func deletePlaceholder(_ placeholder: PlaceholderDefinition) {
        context.delete(placeholder)
        saveContext()
    }

    /// Dupliziert einen Platzhalter
    /// - Parameter placeholder: Der zu duplizierende Platzhalter
    /// - Returns: Der neue Platzhalter
    func duplicatePlaceholder(_ placeholder: PlaceholderDefinition) -> PlaceholderDefinition {
        let duplicate = PlaceholderDefinition(
            key: "\(placeholder.key)_kopie",
            label: "\(placeholder.label) (Kopie)",
            type: placeholder.type,
            options: placeholder.options,
            isGlobal: placeholder.isGlobal,
            defaultValue: placeholder.defaultValue,
            descriptionText: placeholder.descriptionText
        )
        context.insert(duplicate)
        saveContext()
        return duplicate
    }

    /// Validiert einen Platzhalter-Key
    /// - Parameter key: Der zu validierende Key
    /// - Returns: Fehlermeldung oder nil wenn gültig
    func validateKey(_ key: String) -> String? {
        if key.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Der Schlüssel darf nicht leer sein."
        }

        if !detectionService.isValidPlaceholderKey(key) {
            return "Der Schlüssel darf nur Buchstaben, Zahlen, _ und - enthalten."
        }

        // Prüfe, ob Key bereits existiert
        let descriptor = FetchDescriptor<PlaceholderDefinition>(
            predicate: #Predicate { $0.key == key }
        )

        if let existing = try? context.fetch(descriptor), !existing.isEmpty {
            return "Ein Platzhalter mit diesem Schlüssel existiert bereits."
        }

        return nil
    }

    /// Schlägt einen gültigen Key basierend auf einem Label vor
    /// - Parameter label: Das Label
    /// - Returns: Ein gültiger Key-Vorschlag
    func suggestKey(from label: String) -> String {
        return detectionService.suggestKey(from: label)
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
