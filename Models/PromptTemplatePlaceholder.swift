//
//  PromptTemplatePlaceholder.swift
//  PromptHelper
//
//  Created by Claude Code on 2025-11-14.
//

import Foundation
import SwiftData

/// Zuordnung zwischen einem Template und einem Platzhalter
/// Many-to-Many Relationship zwischen PromptTemplate und PlaceholderDefinition
@Model
final class PromptTemplatePlaceholder {
    /// Eindeutige ID
    var id: UUID

    /// Referenz zum Template
    var template: PromptTemplate?

    /// Referenz zur Platzhalter-Definition
    var placeholder: PlaceholderDefinition?

    /// Gibt an, ob dieser Platzhalter für das Template erforderlich ist
    var isRequired: Bool

    /// Sortierreihenfolge (für UI)
    var sortOrder: Int

    /// Optionaler template-spezifischer Standardwert
    /// Überschreibt den globalen Standardwert der PlaceholderDefinition
    var templateSpecificDefaultValue: String?

    // MARK: - Initialisierung

    init(
        id: UUID = UUID(),
        template: PromptTemplate? = nil,
        placeholder: PlaceholderDefinition? = nil,
        isRequired: Bool = true,
        sortOrder: Int = 0,
        templateSpecificDefaultValue: String? = nil
    ) {
        self.id = id
        self.template = template
        self.placeholder = placeholder
        self.isRequired = isRequired
        self.sortOrder = sortOrder
        self.templateSpecificDefaultValue = templateSpecificDefaultValue
    }

    // MARK: - Helper Methods

    /// Gibt den effektiven Standardwert zurück
    /// (template-spezifisch oder global)
    var effectiveDefaultValue: String? {
        templateSpecificDefaultValue ?? placeholder?.defaultValue
    }
}
