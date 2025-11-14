//
//  PromptInstance.swift
//  PromptHelper
//
//  Created by Claude Code on 2025-11-14.
//

import Foundation
import SwiftData

/// Eine konkrete Instanz eines generierten Prompts
/// Speichert die Historie der generierten Prompts mit ausgefüllten Werten
@Model
final class PromptInstance {
    /// Eindeutige ID
    var id: UUID

    /// Referenz zum verwendeten Template
    var template: PromptTemplate?

    /// Ausgefüllte Werte als Dictionary (key -> value)
    /// Für SwiftData serialisiert als Data
    var filledValuesData: Data

    /// Der generierte finale Prompt-Text
    var generatedText: String

    /// Erstellungsdatum
    var createdAt: Date

    /// Optional: Benutzerdefinierte Notizen zu dieser Instanz
    var notes: String?

    // MARK: - Computed Properties

    /// Typsicherer Zugriff auf die ausgefüllten Werte
    var filledValues: [String: String] {
        get {
            guard let decoded = try? JSONDecoder().decode([String: String].self, from: filledValuesData) else {
                return [:]
            }
            return decoded
        }
        set {
            guard let encoded = try? JSONEncoder().encode(newValue) else {
                filledValuesData = Data()
                return
            }
            filledValuesData = encoded
        }
    }

    // MARK: - Initialisierung

    init(
        id: UUID = UUID(),
        template: PromptTemplate? = nil,
        filledValues: [String: String] = [:],
        generatedText: String,
        createdAt: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        self.template = template
        self.generatedText = generatedText
        self.createdAt = createdAt
        self.notes = notes

        // Encode filledValues
        if let encoded = try? JSONEncoder().encode(filledValues) {
            self.filledValuesData = encoded
        } else {
            self.filledValuesData = Data()
        }
    }
}
