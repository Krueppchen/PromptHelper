//
//  TagChipView.swift
//  PromptHelper
//
//  Created by Claude Code on 2025-11-14.
//

import SwiftUI

/// Eine wiederverwendbare Chip-View für Tags
struct TagChipView: View {
    let tag: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Text(tag)
            .font(DesignSystem.Typography.caption)
            .fontWeight(isSelected ? .semibold : .medium)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                Capsule()
                    .fill(isSelected ? DesignSystem.SemanticColor.accent : DesignSystem.SemanticColor.secondaryBackground)
            )
            .foregroundStyle(isSelected ? .white : DesignSystem.SemanticColor.primary)
            .overlay(
                Capsule()
                    .strokeBorder(
                        isSelected ? Color.clear : DesignSystem.SemanticColor.secondary.opacity(0.2),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isSelected ? 1.0 : 0.98)
            .animation(DesignSystem.Animation.quick, value: isSelected)
            .onTapGesture {
                onTap()
            }
    }
}

#Preview {
    HStack {
        TagChipView(tag: "Marketing", isSelected: false) { }
        TagChipView(tag: "Blog", isSelected: true) { }
    }
    .padding()
}
