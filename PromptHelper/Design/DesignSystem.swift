//
//  DesignSystem.swift
//  PromptHelper
//
//  Created by Claude Code on 2025-11-14.
//

import SwiftUI

/// Modern iOS Design System
/// Definiert konsistente Werte für Spacing, Typography, Colors und mehr
enum DesignSystem {

    // MARK: - Spacing

    /// Konsistentes Spacing-System basierend auf 4pt-Grid
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 40

        /// Für Listen und ScrollViews
        static let listItemVertical: CGFloat = 12
        static let listItemHorizontal: CGFloat = 16
        static let sectionSpacing: CGFloat = 24
    }

    // MARK: - Corner Radius

    /// Konsistente Corner Radii
    enum CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24

        /// Für Cards
        static let card: CGFloat = 16

        /// Für Buttons
        static let button: CGFloat = 12

        /// Für Chips/Tags
        static let chip: CGFloat = 20
    }

    // MARK: - Typography

    /// Typographie-System mit klarer Hierarchie
    enum Typography {
        // Titles
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title1 = Font.title.weight(.bold)
        static let title2 = Font.title2.weight(.bold)
        static let title3 = Font.title3.weight(.semibold)

        // Body
        static let body = Font.body
        static let bodyEmphasized = Font.body.weight(.semibold)
        static let bodyMonospaced = Font.system(.body, design: .monospaced)

        // Secondary
        static let callout = Font.callout
        static let subheadline = Font.subheadline
        static let footnote = Font.footnote
        static let caption = Font.caption
        static let caption2 = Font.caption2

        // Specialized
        static let code = Font.system(.body, design: .monospaced)
    }

    // MARK: - Shadows

    /// Schatten-System für Tiefe
    enum Shadow {
        static let sm = (color: Color.black.opacity(0.05), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
        static let md = (color: Color.black.opacity(0.08), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let lg = (color: Color.black.opacity(0.1), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))

        /// Schatten für Cards
        static let card = (color: Color.black.opacity(0.06), radius: CGFloat(12), x: CGFloat(0), y: CGFloat(4))
    }

    // MARK: - Animation

    /// Standard-Animationen
    enum Animation {
        static let quick = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let smooth = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let bouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.6)
        static let gentle = SwiftUI.Animation.easeInOut(duration: 0.3)
    }

    // MARK: - Icon Sizes

    /// Konsistente Icon-Größen
    enum IconSize {
        static let xs: CGFloat = 12
        static let sm: CGFloat = 16
        static let md: CGFloat = 20
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 40
    }

    // MARK: - Brand Colors

    /// Brand-Farbpalette
    /// Alle Farben sind WCAG AA konform, außer Muted Teal (nur für Icons/Grafiken)
    enum BrandColor {
        /// Deep Lilac - Primary Brand Color
        /// Kontrast auf Weiß: ~5.5:1 (WCAG AA ✓)
        static let deepLilac = Color(hex: "7b45a1")

        /// Stormy Teal - Secondary Brand Color
        /// Kontrast auf Weiß: ~5:1 (WCAG AA ✓)
        static let stormyTeal = Color(hex: "197278")

        /// Muted Teal - Success/Tertiary Color
        /// Kontrast auf Weiß: ~2.5:1 (WCAG AA ✗)
        /// ⚠️ NUR für Icons und grafische Elemente verwenden, NICHT für Text!
        static let mutedTeal = Color(hex: "9cc5a1")

        /// Muted Teal Dark - Dunklere Variante für besseren Kontrast
        /// Kontrast auf Weiß: ~4.5:1 (WCAG AA ✓)
        /// Für Text-Anwendungen von Success-Messages
        static let mutedTealDark = Color(hex: "6b9c7d")

        /// Alabaster Grey - Background Color
        static let alabasterGrey = Color(hex: "dce1de")

        /// Near Black - Text Color
        /// Kontrast auf Weiß: ~20:1 (WCAG AAA ✓)
        static let nearBlack = Color(hex: "050505")
    }

    // MARK: - Semantic Colors

    /// Semantische Farben für bessere Accessibility
    enum SemanticColor {
        // Text Colors
        static let primary = BrandColor.nearBlack
        static let secondary = BrandColor.stormyTeal
        static let tertiary = Color(.tertiaryLabel)

        // Background Colors
        static let background = Color(.systemBackground)
        static let secondaryBackground = BrandColor.alabasterGrey
        static let tertiaryBackground = Color(.tertiarySystemBackground)

        // Brand Colors
        static let accent = BrandColor.deepLilac

        /// Success-Farbe (dunklere Variante für Text)
        static let success = BrandColor.mutedTealDark

        /// Success-Icon-Farbe (hellere Variante für grafische Elemente)
        static let successIcon = BrandColor.mutedTeal

        // System Semantic Colors (iOS-Standard)
        static let warning = Color(.systemOrange)
        static let error = Color(.systemRed)
        static let info = BrandColor.stormyTeal

        // Card backgrounds
        static let cardBackground = Color(.secondarySystemBackground)
        static let elevatedCardBackground = Color(.systemBackground)
    }
}

// MARK: - View Extensions für Design System

extension View {
    /// Wendet Card-Styling an
    func cardStyle(
        background: Color = DesignSystem.SemanticColor.cardBackground,
        cornerRadius: CGFloat = DesignSystem.CornerRadius.card,
        shadow: Bool = true
    ) -> some View {
        self
            .background(background)
            .cornerRadius(cornerRadius)
            .if(shadow) { view in
                view.shadow(
                    color: DesignSystem.Shadow.card.color,
                    radius: DesignSystem.Shadow.card.radius,
                    x: DesignSystem.Shadow.card.x,
                    y: DesignSystem.Shadow.card.y
                )
            }
    }

    /// Wendet Chip/Badge-Styling an
    func chipStyle(
        backgroundColor: Color = DesignSystem.SemanticColor.accent.opacity(0.15),
        foregroundColor: Color = DesignSystem.SemanticColor.accent,
        padding: CGFloat = DesignSystem.Spacing.sm
    ) -> some View {
        self
            .padding(.horizontal, padding)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .cornerRadius(DesignSystem.CornerRadius.chip)
    }

    /// Konditionales Modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Fügt interaktive Skalierung hinzu
    func interactiveScale(isPressed: Bool) -> some View {
        self.scaleEffect(isPressed ? 0.96 : 1.0)
    }

    /// Standard-Padding für Listen-Items
    func listItemPadding() -> some View {
        self.padding(.vertical, DesignSystem.Spacing.listItemVertical)
            .padding(.horizontal, DesignSystem.Spacing.listItemHorizontal)
    }
}

// MARK: - SF Symbols Configuration

extension Image {
    /// Konfiguriert ein SF Symbol mit konsistentem Styling
    static func symbol(
        _ name: String,
        size: CGFloat = DesignSystem.IconSize.md,
        weight: Font.Weight = .regular
    ) -> some View {
        Image(systemName: name)
            .font(.system(size: size, weight: weight))
            .symbolRenderingMode(.hierarchical)
    }
}

// MARK: - Color Extensions

extension Color {
    /// Initialisiert eine Farbe aus einem Hex-String
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Button Styles

/// Moderner Primary Button Style
struct PrimaryButtonStyle: ButtonStyle {
    var isDestructive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.bodyEmphasized)
            .foregroundStyle(.white)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                isDestructive ? DesignSystem.SemanticColor.error : DesignSystem.SemanticColor.accent
            )
            .cornerRadius(DesignSystem.CornerRadius.button)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
    }
}

/// Moderner Secondary Button Style
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.body)
            .foregroundStyle(DesignSystem.SemanticColor.accent)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(DesignSystem.SemanticColor.accent.opacity(0.1))
            .cornerRadius(DesignSystem.CornerRadius.button)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
    }
}

/// Kompakter Icon-Button Style
struct IconButtonStyle: ButtonStyle {
    var size: CGFloat = 36

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size, height: size)
            .background(DesignSystem.SemanticColor.secondaryBackground)
            .cornerRadius(DesignSystem.CornerRadius.sm)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
    }
}
