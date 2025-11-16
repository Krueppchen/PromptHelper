//
//  ModernCard.swift
//  PromptHelper
//
//  Created by Claude Code on 2025-11-14.
//

import SwiftUI

/// Moderne Card-Komponente mit iOS-Design-Richtlinien
struct ModernCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = DesignSystem.Spacing.md
    var backgroundColor: Color = DesignSystem.SemanticColor.cardBackground
    var hasShadow: Bool = true

    init(
        padding: CGFloat = DesignSystem.Spacing.md,
        backgroundColor: Color = DesignSystem.SemanticColor.cardBackground,
        hasShadow: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.backgroundColor = backgroundColor
        self.hasShadow = hasShadow
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(DesignSystem.CornerRadius.card)
            .if(hasShadow) { view in
                view.shadow(
                    color: DesignSystem.Shadow.card.color,
                    radius: DesignSystem.Shadow.card.radius,
                    x: DesignSystem.Shadow.card.x,
                    y: DesignSystem.Shadow.card.y
                )
            }
    }
}

/// Badge/Chip-Komponente für Tags und Status-Anzeigen
struct ModernBadge: View {
    let text: String
    var icon: String? = nil
    var style: BadgeStyle = .default

    enum BadgeStyle {
        case `default`
        case accent
        case success
        case warning
        case info

        var backgroundColor: Color {
            switch self {
            case .default: return DesignSystem.SemanticColor.secondary.opacity(0.15)
            case .accent: return DesignSystem.SemanticColor.accent.opacity(0.15)
            case .success: return DesignSystem.SemanticColor.success.opacity(0.15)
            case .warning: return DesignSystem.SemanticColor.warning.opacity(0.15)
            case .info: return DesignSystem.SemanticColor.info.opacity(0.15)
            }
        }

        var foregroundColor: Color {
            switch self {
            case .default: return DesignSystem.SemanticColor.secondary
            case .accent: return DesignSystem.SemanticColor.accent
            case .success: return DesignSystem.SemanticColor.successIcon
            case .warning: return DesignSystem.SemanticColor.warning
            case .info: return DesignSystem.SemanticColor.info
            }
        }
    }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xxs) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: DesignSystem.IconSize.xs, weight: .semibold))
            }
            Text(text)
                .font(DesignSystem.Typography.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(style.backgroundColor)
        .foregroundStyle(style.foregroundColor)
        .cornerRadius(DesignSystem.CornerRadius.chip)
    }
}

/// Moderner Icon-Badge (z.B. für Favoriten, Status-Icons)
struct ModernIconBadge: View {
    let icon: String
    var size: CGFloat = 44
    var iconSize: CGFloat = DesignSystem.IconSize.lg
    var backgroundColor: Color = DesignSystem.SemanticColor.accent.opacity(0.15)
    var foregroundColor: Color = DesignSystem.SemanticColor.accent

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(backgroundColor)
                .frame(width: size, height: size)

            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(foregroundColor)
                .symbolRenderingMode(.hierarchical)
        }
    }
}

/// Section Header mit optionalem Trailing-Content
struct ModernSectionHeader<TrailingContent: View>: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    let trailingContent: TrailingContent?

    init(
        _ title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        @ViewBuilder trailingContent: () -> TrailingContent
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.trailingContent = trailingContent()
    }

    init(
        _ title: String,
        subtitle: String? = nil,
        icon: String? = nil
    ) where TrailingContent == EmptyView {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.trailingContent = nil
    }

    var body: some View {
        HStack(alignment: .center) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: DesignSystem.IconSize.md, weight: .semibold))
                        .foregroundStyle(DesignSystem.SemanticColor.accent)
                }

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    Text(title)
                        .font(DesignSystem.Typography.title3)
                        .foregroundStyle(DesignSystem.SemanticColor.primary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.SemanticColor.secondary)
                    }
                }
            }

            Spacer()

            if let trailingContent = trailingContent {
                trailingContent
            }
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
}

/// Empty State View mit Icon und Beschreibung
struct ModernEmptyState: View {
    let icon: String
    let title: String
    var message: String? = nil
    var action: (() -> Void)? = nil
    var actionLabel: String? = nil

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(DesignSystem.SemanticColor.tertiary)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.SemanticColor.primary)
                    .multilineTextAlignment(.center)

                if let message = message {
                    Text(message)
                        .font(DesignSystem.Typography.callout)
                        .foregroundStyle(DesignSystem.SemanticColor.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            if let action = action, let actionLabel = actionLabel {
                Button(action: action) {
                    Label(actionLabel, systemImage: "plus.circle.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, DesignSystem.Spacing.sm)
            }
        }
        .padding(DesignSystem.Spacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Success/Error Toast Notification
struct ModernToast: View {
    enum ToastType {
        case success
        case error
        case info

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .success: return DesignSystem.SemanticColor.successIcon
            case .error: return DesignSystem.SemanticColor.error
            case .info: return DesignSystem.SemanticColor.info
            }
        }
    }

    let message: String
    let type: ToastType

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: type.icon)
                .font(.system(size: DesignSystem.IconSize.md, weight: .semibold))

            Text(message)
                .font(DesignSystem.Typography.subheadline)
                .fontWeight(.medium)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(type.color)
        .cornerRadius(DesignSystem.CornerRadius.button)
        .shadow(
            color: DesignSystem.Shadow.md.color,
            radius: DesignSystem.Shadow.md.radius,
            x: DesignSystem.Shadow.md.x,
            y: DesignSystem.Shadow.md.y
        )
    }
}

// MARK: - Previews

#Preview("Cards") {
    VStack(spacing: DesignSystem.Spacing.md) {
        ModernCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Card Title")
                    .font(DesignSystem.Typography.title3)
                Text("This is a modern card with proper spacing and shadow.")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.SemanticColor.secondary)
            }
        }

        ModernCard(hasShadow: false) {
            Text("Card without shadow")
        }
    }
    .padding()
    .background(DesignSystem.SemanticColor.background)
}

#Preview("Badges") {
    VStack(spacing: DesignSystem.Spacing.md) {
        HStack {
            ModernBadge(text: "Default")
            ModernBadge(text: "Accent", style: .accent)
            ModernBadge(text: "Success", icon: "checkmark", style: .success)
        }

        HStack {
            ModernIconBadge(icon: "star.fill", backgroundColor: .yellow.opacity(0.2), foregroundColor: .yellow)
            ModernIconBadge(icon: "doc.text", backgroundColor: .blue.opacity(0.15), foregroundColor: .blue)
        }
    }
    .padding()
}

#Preview("Empty State") {
    ModernEmptyState(
        icon: "doc.text.magnifyingglass",
        title: "Keine Templates gefunden",
        message: "Erstellen Sie ein neues Template mit dem + Button",
        action: { print("Action") },
        actionLabel: "Neues Template"
    )
}

#Preview("Toasts") {
    VStack(spacing: DesignSystem.Spacing.md) {
        ModernToast(message: "Erfolgreich gespeichert", type: .success)
        ModernToast(message: "Fehler beim Laden", type: .error)
        ModernToast(message: "Neue Benachrichtigung", type: .info)
    }
    .padding()
}
