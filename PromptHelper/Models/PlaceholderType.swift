//
//  PlaceholderType.swift
//  PromptHelper
//
//  Created by Claude Code on 2025-11-14.
//

import Foundation

/// Enum für verschiedene Platzhalter-Typen
/// Definiert, wie ein Platzhalter in der UI dargestellt und validiert wird
enum PlaceholderType: String, Codable, CaseIterable {
    /// Einfaches Textfeld
    case text

    /// Numerische Eingabe
    case number

    /// Datums-Auswahl
    case date

    /// Einzelauswahl aus vordefinierten Optionen
    case singleChoice

    /// Mehrfachauswahl aus vordefinierten Optionen
    case multiChoice

    /// Menschenlesbarer Name für UI
    var displayName: String {
        switch self {
        case .text:
            return "Text"
        case .number:
            return "Zahl"
        case .date:
            return "Datum"
        case .singleChoice:
            return "Einzelauswahl"
        case .multiChoice:
            return "Mehrfachauswahl"
        }
    }

    /// Gibt an, ob dieser Typ Optionen benötigt
    var requiresOptions: Bool {
        switch self {
        case .singleChoice, .multiChoice:
            return true
        case .text, .number, .date:
            return false
        }
    }

    /// SF Symbol Icon-Name für jeden Typ
    var iconName: String {
        switch self {
        case .text:
            return "textformat"
        case .number:
            return "number"
        case .date:
            return "calendar"
        case .singleChoice:
            return "list.bullet.circle"
        case .multiChoice:
            return "checklist"
        }
    }
}
