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
            .font(.caption)
            .fontWeight(isSelected ? .semibold : .regular)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Group {
                    if isSelected {
                        Capsule()
                            .fill(Color.accentColor)
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
                    } else {
                        Capsule()
                            .fill(Color.gray.opacity(0.15))
                    }
                }
            )
            .foregroundStyle(isSelected ? .white : .primary)
            .overlay(
                Capsule()
                    .strokeBorder(
                        isSelected ? Color.clear : Color.gray.opacity(0.2),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isSelected ? 1.0 : 0.98)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
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
