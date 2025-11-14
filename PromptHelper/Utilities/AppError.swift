//
//  AppError.swift
//  PromptHelper
//
//  Created by Claude Code on 2025-11-14.
//

import Foundation

/// Zentrale Fehlerbehandlung für die App
enum AppError: LocalizedError {
    case persistenceError(String)
    case validationError(String)
    case renderError(String)
    case placeholderNotFound(String)
    case templateNotFound
    case missingRequiredPlaceholder(String)
    case invalidPlaceholderValue(String, String) // key, reason

    var errorDescription: String? {
        switch self {
        case .persistenceError(let message):
            return "Speicherfehler: \(message)"
        case .validationError(let message):
            return "Validierungsfehler: \(message)"
        case .renderError(let message):
            return "Fehler beim Generieren: \(message)"
        case .placeholderNotFound(let key):
            return "Platzhalter '\(key)' wurde nicht gefunden."
        case .templateNotFound:
            return "Template wurde nicht gefunden."
        case .missingRequiredPlaceholder(let key):
            return "Pflichtfeld '\(key)' muss ausgefüllt werden."
        case .invalidPlaceholderValue(let key, let reason):
            return "Ungültiger Wert für '\(key)': \(reason)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .persistenceError:
            return "Bitte versuchen Sie es erneut oder starten Sie die App neu."
        case .validationError:
            return "Bitte überprüfen Sie Ihre Eingaben."
        case .renderError:
            return "Bitte überprüfen Sie Ihr Template und die Platzhalter."
        case .placeholderNotFound:
            return "Bitte erstellen Sie zuerst die benötigte Platzhalter-Definition."
        case .templateNotFound:
            return "Bitte wählen Sie ein gültiges Template aus."
        case .missingRequiredPlaceholder:
            return "Bitte füllen Sie alle Pflichtfelder aus."
        case .invalidPlaceholderValue:
            return "Bitte geben Sie einen gültigen Wert ein."
        }
    }
}
