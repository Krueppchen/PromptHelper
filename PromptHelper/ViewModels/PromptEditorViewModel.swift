//
//  PromptEditorViewModel.swift
//  PromptHelper
//
//  Created by Claude Code on 2025-11-14.
//

import Foundation
import SwiftData
import SwiftUI

/// ViewModel für den Prompt-Editor
@MainActor
@Observable
final class PromptEditorViewModel {
    /// Das zu bearbeitende Template
    var template: PromptTemplate

    /// Temporäre Editier-Werte
    var editTitle: String
    var editDescription: String
    var editContent: String
    var editTags: [String]

    /// Neuer Tag-Input
    var newTagInput: String = ""

    /// Fehlermeldung
    var errorMessage: String?

    /// Erfolgs-Nachricht
    var successMessage: String?

    /// Navigation zu Platzhalter-Ansicht
    var showPlaceholderManagement = false

    /// Navigation zu Generator
    var showGenerator = false

    /// ModelContext für Datenbank-Operationen
    private let context: ModelContext

    /// Service für Platzhalter-Erkennung
    private let detectionService = PlaceholderDetectionService()

    // MARK: - Initialisierung

    init(template: PromptTemplate, context: ModelContext) {
        self.template = template
        self.context = context

        // Initialisiere Editier-Werte
        self.editTitle = template.title
        self.editDescription = template.descriptionText ?? ""
        self.editContent = template.content
        self.editTags = template.tags
    }

    // MARK: - Public Methods

    /// Speichert die Änderungen
    func save() {
        // Validierung
        guard !editTitle.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Der Titel darf nicht leer sein."
            return
        }

        // Aktualisiere Template
        template.title = editTitle
        template.descriptionText = editDescription.isEmpty ? nil : editDescription
        template.content = editContent
        template.tags = editTags
        template.markAsUpdated()

        // Speichere Context
        do {
            try context.save()
            successMessage = "Gespeichert"

            // Verstecke Success-Message nach 2 Sekunden
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                successMessage = nil
            }
        } catch {
            errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
        }
    }

    /// Erkennt und synchronisiert Platzhalter
    func detectAndSyncPlaceholders() {
        // Lade alle globalen Platzhalter
        let descriptor = FetchDescriptor<PlaceholderDefinition>(
            predicate: #Predicate { $0.isGlobal == true }
        )

        guard let globalPlaceholders = try? context.fetch(descriptor) else {
            errorMessage = "Fehler beim Laden der Platzhalter."
            return
        }

        // Synchronisiere
        detectionService.syncPlaceholders(
            for: template,
            context: context,
            globalPlaceholders: globalPlaceholders
        )

        // Speichere
        do {
            try context.save()
            successMessage = "Platzhalter synchronisiert"
        } catch {
            errorMessage = "Fehler beim Synchronisieren: \(error.localizedDescription)"
        }
    }

    /// Fügt einen neuen Tag hinzu
    func addTag() {
        let tag = newTagInput.trimmingCharacters(in: .whitespaces)
        guard !tag.isEmpty else { return }
        guard !editTags.contains(tag) else {
            newTagInput = ""
            return
        }

        editTags.append(tag)
        newTagInput = ""
    }

    /// Entfernt einen Tag
    /// - Parameter tag: Der zu entfernende Tag
    func removeTag(_ tag: String) {
        editTags.removeAll { $0 == tag }
    }

    /// Fügt einen Platzhalter am Cursor ein
    /// - Parameter key: Der Platzhalter-Key
    /// - Returns: Der formatierte Platzhalter
    func insertPlaceholder(key: String) -> String {
        return "{{\(key)}}"
    }

    /// Gibt alle erkannten Platzhalter-Keys zurück
    func getDetectedPlaceholderKeys() -> [String] {
        return editContent.extractPlaceholderKeys()
    }

    /// Gibt fehlende Platzhalter-Definitionen zurück
    func getMissingPlaceholderDefinitions() -> [String] {
        let descriptor = FetchDescriptor<PlaceholderDefinition>(
            predicate: #Predicate { $0.isGlobal == true }
        )

        guard let globalPlaceholders = try? context.fetch(descriptor) else {
            return []
        }

        return detectionService.findMissingDefinitions(
            for: template,
            globalPlaceholders: globalPlaceholders
        )
    }
}
