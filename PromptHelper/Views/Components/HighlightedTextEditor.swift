//
//  HighlightedTextEditor.swift
//  PromptHelper
//
//  Created by Claude Code on 2025-11-16.
//

import SwiftUI
import UIKit

/// TextEditor mit Syntax-Highlighting für Platzhalter
/// Zeigt Platzhalter im Format {{key}} in einer benutzerdefinierten Farbe an
struct HighlightedTextEditor: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let highlightColor: UIColor
    let font: UIFont

    init(
        text: Binding<String>,
        placeholder: String = "",
        highlightColor: UIColor = UIColor(DesignSystem.SemanticColor.accent),
        font: UIFont = .systemFont(ofSize: 17)
    ) {
        self._text = text
        self.placeholder = placeholder
        self.highlightColor = highlightColor
        self.font = font
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = font
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 20, left: 16, bottom: 20, right: 16)
        textView.autocapitalizationType = .sentences
        textView.autocorrectionType = .default
        textView.spellCheckingType = .default
        textView.smartQuotesType = .default
        textView.smartDashesType = .default

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        // Nur updaten wenn sich der Text geändert hat
        if uiView.attributedText.string != text {
            let attributedString = highlightPlaceholders(in: text)

            // Cursor-Position merken
            let selectedRange = uiView.selectedRange

            uiView.attributedText = attributedString

            // Cursor-Position wiederherstellen
            if selectedRange.location <= uiView.attributedText.length {
                uiView.selectedRange = selectedRange
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: HighlightedTextEditor

        init(_ parent: HighlightedTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            // Update binding
            parent.text = textView.text

            // Re-apply highlighting
            let attributedString = parent.highlightPlaceholders(in: textView.text)
            let selectedRange = textView.selectedRange

            textView.attributedText = attributedString

            // Cursor-Position wiederherstellen
            if selectedRange.location <= textView.attributedText.length {
                textView.selectedRange = selectedRange
            }
        }
    }

    // MARK: - Highlighting Logic

    /// Erstellt einen AttributedString mit hervorgehobenen Platzhaltern
    private func highlightPlaceholders(in text: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text)

        // Basis-Attribute für normalen Text
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.label
        ]
        attributedString.addAttributes(baseAttributes, range: NSRange(location: 0, length: text.utf16.count))

        // Finde alle Platzhalter und hebe sie hervor
        let pattern = "\\{\\{[^}]+\\}\\}"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return attributedString
        }

        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

        // Highlight-Attribute für Platzhalter
        let highlightAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: highlightColor,
            .font: UIFont.systemFont(ofSize: font.pointSize, weight: .semibold)
        ]

        for match in matches {
            attributedString.addAttributes(highlightAttributes, range: match.range)
        }

        return attributedString
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var text = "Erstelle einen Blog-Post über {{thema}} für {{zielgruppe}}.\nDer Ton sollte {{tonalitaet}} sein."

        var body: some View {
            VStack {
                HighlightedTextEditor(
                    text: $text,
                    placeholder: "Beginnen Sie mit dem Schreiben..."
                )
                .frame(height: 300)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
                )

                Text("Zeichen: \(text.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
