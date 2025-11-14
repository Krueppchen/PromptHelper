//
//  PromptRenderService.swift
//  PromptHelper
//
//  Created by Claude Code on 2025-11-14.
//

import Foundation

/// Service für das Rendern von Prompts
/// Ersetzt Platzhalter im Template-Content durch tatsächliche Werte
final class PromptRenderService {

    // MARK: - Public Methods

    /// Rendert einen Prompt durch Ersetzen aller Platzhalter
    /// - Parameters:
    ///   - template: Das zu rendernde Template
    ///   - values: Dictionary mit ausgefüllten Werten (key -> value)
    /// - Returns: Result mit dem gerenderten String oder einem Fehler
    func render(
        template: PromptTemplate,
        with values: [String: String]
    ) -> Result<String, AppError> {
        // Validiere, dass alle erforderlichen Platzhalter ausgefüllt sind
        if let validationError = validateRequiredPlaceholders(template: template, values: values) {
            return .failure(validationError)
        }

        // Ersetze Platzhalter
        let renderedContent = template.content.replacingPlaceholders(with: values)

        // Prüfe, ob noch unausgefüllte Platzhalter vorhanden sind
        let unfilledKeys = renderedContent.extractPlaceholderKeys()
        if !unfilledKeys.isEmpty {
            return .failure(.renderError("Folgende Platzhalter sind noch nicht ausgefüllt: \(unfilledKeys.joined(separator: ", "))"))
        }

        return .success(renderedContent)
    }

    /// Validiert, ob alle erforderlichen Platzhalter ausgefüllt sind
    /// - Parameters:
    ///   - template: Das Template
    ///   - values: Die ausgefüllten Werte
    /// - Returns: Optional AppError, wenn Validierung fehlschlägt
    func validateRequiredPlaceholders(
        template: PromptTemplate,
        values: [String: String]
    ) -> AppError? {
        guard let placeholders = template.placeholders else {
            return nil
        }

        // Finde alle erforderlichen Platzhalter
        let requiredPlaceholders = placeholders.filter { $0.isRequired }

        // Prüfe, ob alle erforderlichen Platzhalter ausgefüllt sind
        for templatePlaceholder in requiredPlaceholders {
            guard let placeholder = templatePlaceholder.placeholder else {
                continue
            }

            let key = placeholder.key
            let value = values[key] ?? ""

            // Prüfe, ob Wert vorhanden und nicht leer
            if value.trimmingCharacters(in: .whitespaces).isEmpty {
                return .missingRequiredPlaceholder(placeholder.label)
            }

            // Type-spezifische Validierung
            if let error = validateValue(value, for: placeholder) {
                return error
            }
        }

        return nil
    }

    /// Validiert einen Wert gegen die Platzhalter-Definition
    /// - Parameters:
    ///   - value: Der zu validierende Wert
    ///   - placeholder: Die Platzhalter-Definition
    /// - Returns: Optional AppError bei Validierungsfehler
    func validateValue(_ value: String, for placeholder: PlaceholderDefinition) -> AppError? {
        switch placeholder.type {
        case .number:
            // Prüfe, ob es eine gültige Zahl ist
            if Double(value) == nil {
                return .invalidPlaceholderValue(placeholder.label, "Muss eine Zahl sein")
            }

        case .singleChoice:
            // Prüfe, ob der Wert in den Optionen enthalten ist
            if !placeholder.options.contains(value) && !value.isEmpty {
                return .invalidPlaceholderValue(placeholder.label, "Muss eine der vordefinierten Optionen sein")
            }

        case .multiChoice:
            // Bei Multi-Choice: Werte sind komma-separiert
            let selectedValues = value.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            let invalidValues = selectedValues.filter { !placeholder.options.contains($0) && !$0.isEmpty }

            if !invalidValues.isEmpty {
                return .invalidPlaceholderValue(placeholder.label, "Ungültige Auswahl: \(invalidValues.joined(separator: ", "))")
            }

        case .text, .date:
            // Keine spezielle Validierung nötig
            break
        }

        return nil
    }

    /// Erstellt eine Vorschau des gerenderten Prompts mit Markierungen für fehlende Werte
    /// - Parameters:
    ///   - template: Das Template
    ///   - values: Die bisher ausgefüllten Werte
    /// - Returns: String mit Vorschau (fehlende Platzhalter bleiben als {{key}} stehen)
    func preview(template: PromptTemplate, with values: [String: String]) -> String {
        return template.content.replacingPlaceholders(with: values)
    }
}
