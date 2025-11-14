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
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isSelected ? Color.accentColor : Color.gray.opacity(0.2)
            )
            .foregroundStyle(
                isSelected ? .white : .primary
            )
            .clipShape(Capsule())
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
