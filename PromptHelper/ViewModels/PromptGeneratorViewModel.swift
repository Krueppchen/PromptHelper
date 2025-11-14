//
//  PromptGeneratorViewModel.swift
//  PromptHelper
//
//  Created by Claude Code on 2025-11-14.
//

import Foundation
import SwiftData
import SwiftUI

/// ViewModel für den Prompt-Generator
@MainActor
@Observable
final class PromptGeneratorViewModel {
    /// Das Template
    let template: PromptTemplate

    /// Ausgefüllte Werte (key -> value)
    var filledValues: [String: String] = [:]

    /// Generierter Prompt
    var generatedPrompt: String = ""

    /// Vorschau-Modus aktiv
    var showPreview: Bool = false

    /// Fehlermeldung
    var errorMessage: String?

    /// Erfolgs-Nachricht
    var successMessage: String?

    /// ModelContext für Datenbank-Operationen
    private let context: ModelContext

    /// Render-Service
    private let renderService = PromptRenderService()

    // MARK: - Computed Properties

    /// Sortierte Liste der Platzhalter
    var sortedPlaceholders: [PromptTemplatePlaceholder] {
        (template.placeholders ?? []).sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Gibt an, ob alle Pflicht-Platzhalter ausgefüllt sind
    var allRequiredFilled: Bool {
        for templatePlaceholder in template.placeholders ?? [] {
            guard templatePlaceholder.isRequired else { continue }
            guard let placeholder = templatePlaceholder.placeholder else { continue }

            let value = filledValues[placeholder.key] ?? ""
            if value.trimmingCharacters(in: .whitespaces).isEmpty {
                return false
            }
        }
        return true
    }

    // MARK: - Initialisierung

    init(template: PromptTemplate, context: ModelContext) {
        self.template = template
        self.context = context

        // Initialisiere mit Standardwerten
        for templatePlaceholder in template.placeholders ?? [] {
            guard let placeholder = templatePlaceholder.placeholder else { continue }

            if let defaultValue = templatePlaceholder.effectiveDefaultValue {
                filledValues[placeholder.key] = defaultValue
            }
        }

        // Erstelle initiale Vorschau
        updatePreview()
    }

    // MARK: - Public Methods

    /// Generiert den finalen Prompt
    func generatePrompt() {
        let result = renderService.render(template: template, with: filledValues)

        switch result {
        case .success(let prompt):
            generatedPrompt = prompt
            successMessage = "Prompt generiert!"
            errorMessage = nil

            // Speichere in Historie (optional)
            saveToHistory(prompt: prompt)

        case .failure(let error):
            errorMessage = error.localizedDescription
            successMessage = nil
        }
    }

    /// Aktualisiert die Vorschau
    func updatePreview() {
        generatedPrompt = renderService.preview(template: template, with: filledValues)
    }

    /// Kopiert den generierten Prompt in die Zwischenablage
    func copyToClipboard() {
        #if os(iOS)
        UIPasteboard.general.string = generatedPrompt
        successMessage = "In Zwischenablage kopiert!"

        // Verstecke Success-Message nach 2 Sekunden
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            successMessage = nil
        }
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(generatedPrompt, forType: .string)
        successMessage = "In Zwischenablage kopiert!"

        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            successMessage = nil
        }
        #endif
    }

    /// Setzt alle Werte zurück
    func reset() {
        filledValues.removeAll()

        // Setze Standardwerte
        for templatePlaceholder in template.placeholders ?? [] {
            guard let placeholder = templatePlaceholder.placeholder else { continue }

            if let defaultValue = templatePlaceholder.effectiveDefaultValue {
                filledValues[placeholder.key] = defaultValue
            }
        }

        updatePreview()
    }

    // MARK: - Private Methods

    /// Speichert den generierten Prompt in der Historie
    private func saveToHistory(prompt: String) {
        let instance = PromptInstance(
            template: template,
            filledValues: filledValues,
            generatedText: prompt
        )

        context.insert(instance)

        do {
            try context.save()
        } catch {
            print("Error saving to history: \(error)")
        }
    }
}
