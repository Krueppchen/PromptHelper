//
//  HapticFeedback.swift
//  PromptHelper
//
//  Created by Claude Code on 2025-11-16.
//

import UIKit

/// Utility für haptisches Feedback gemäß iOS Best Practices
enum HapticFeedback {

    // MARK: - Impact Feedback

    /// Leichtes haptisches Feedback (z.B. für Auswahl)
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Mittleres haptisches Feedback (z.B. für Buttons)
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Starkes haptisches Feedback (z.B. für wichtige Aktionen)
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    // MARK: - Notification Feedback

    /// Erfolgs-Feedback (z.B. nach erfolgreichem Kopieren)
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Warnung-Feedback (z.B. bei Validierungsfehlern)
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    /// Fehler-Feedback (z.B. bei Fehlermeldungen)
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    // MARK: - Selection Feedback

    /// Auswahl-Feedback (z.B. beim Durchscrollen von Optionen)
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
