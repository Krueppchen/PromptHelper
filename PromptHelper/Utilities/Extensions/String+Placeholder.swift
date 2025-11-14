//
//  String+Placeholder.swift
//  PromptHelper
//
//  Created by Claude Code on 2025-11-14.
//

import Foundation

extension String {
    /// Extrahiert alle Platzhalter-Keys aus einem String
    /// Format: {{key}}
    func extractPlaceholderKeys() -> [String] {
        let pattern = "\\{\\{([^}]+)\\}\\}"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }

        let nsString = self as NSString
        let matches = regex.matches(in: self, options: [], range: NSRange(location: 0, length: nsString.length))

        return matches.compactMap { match in
            guard match.numberOfRanges >= 2 else { return nil }
            let range = match.range(at: 1)
            return nsString.substring(with: range).trimmingCharacters(in: .whitespaces)
        }
    }

    /// Ersetzt Platzhalter im Format {{key}} durch die entsprechenden Werte
    /// - Parameter values: Dictionary mit key-value Paaren
    /// - Returns: String mit ersetzten Platzhaltern
    func replacingPlaceholders(with values: [String: String]) -> String {
        var result = self

        for (key, value) in values {
            let placeholder = "{{\(key)}}"
            result = result.replacingOccurrences(of: placeholder, with: value)
        }

        return result
    }

    /// Prüft, ob der String noch nicht ausgefüllte Platzhalter enthält
    func hasUnfilledPlaceholders() -> Bool {
        let pattern = "\\{\\{[^}]+\\}\\}"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return false
        }
        let range = NSRange(location: 0, length: self.utf16.count)
        return regex.firstMatch(in: self, options: [], range: range) != nil
    }

    /// Findet alle nicht ausgefüllten Platzhalter-Keys
    func unfilledPlaceholderKeys() -> [String] {
        return extractPlaceholderKeys()
    }
}

extension String {
    /// Prüft, ob ein String ein gültiger Pattern-Match ist
    func matches(pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return false
        }
        let range = NSRange(location: 0, length: self.utf16.count)
        return regex.firstMatch(in: self, options: [], range: range) != nil
    }

    /// Prüft, ob der String ein gültiger Platzhalter-Key ist
    /// (keine Leerzeichen, keine Sonderzeichen außer _ und -)
    func isValidPlaceholderKey() -> Bool {
        let pattern = "^[a-zA-Z0-9_-]+$"
        return matches(pattern: pattern)
    }
}
