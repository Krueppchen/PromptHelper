//
//  FlowLayout.swift
//  PromptHelper
//
//  Created by Claude Code on 2025-11-16.
//

import SwiftUI

/// Ein Flow-Layout, das Elemente in mehreren Zeilen anordnet
struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    let content: () -> Content

    @State private var totalHeight: CGFloat = 0

    init(spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
        .frame(height: totalHeight)
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width: CGFloat = 0
        var height: CGFloat = 0
        var lastHeight: CGFloat = 0

        return ZStack(alignment: .topLeading) {
            ForEach(Array(Mirror(reflecting: content()).children.enumerated()), id: \.offset) { index, child in
                if let view = child.value as? AnyView {
                    view
                        .alignmentGuide(.leading) { dimension in
                            if abs(width - dimension.width) > geometry.size.width {
                                width = 0
                                height -= lastHeight + spacing
                            }
                            let result = width
                            if index == Mirror(reflecting: content()).children.count - 1 {
                                width = 0
                            } else {
                                width -= dimension.width + spacing
                            }
                            return result
                        }
                        .alignmentGuide(.top) { dimension in
                            let result = height
                            if index == Mirror(reflecting: content()).children.count - 1 {
                                height = 0
                            }
                            lastHeight = dimension.height
                            return result
                        }
                }
            }
        }
        .background(
            GeometryReader { geometry in
                Color.clear.preference(
                    key: HeightPreferenceKey.self,
                    value: geometry.size.height
                )
            }
        )
        .onPreferenceChange(HeightPreferenceKey.self) { height in
            self.totalHeight = height
        }
    }
}

struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Simplified FlowLayout for Tags

/// Vereinfachtes Flow-Layout speziell für Tags
struct TagFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let width = proposal.replacingUnspecifiedDimensions().width
        let height = rows.reduce(0) { $0 + $1.maxHeight } + CGFloat(max(0, rows.count - 1)) * spacing
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY

        for row in rows {
            var x = bounds.minX

            for index in row.indices {
                let subview = subviews[index]
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
                x += size.width + spacing
            }

            y += row.maxHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row()
        let maxWidth = proposal.replacingUnspecifiedDimensions().width

        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)

            if currentRow.width + size.width + (currentRow.indices.isEmpty ? 0 : spacing) > maxWidth {
                if !currentRow.indices.isEmpty {
                    rows.append(currentRow)
                }
                currentRow = Row()
            }

            currentRow.add(index: index, width: size.width, height: size.height, spacing: spacing)
        }

        if !currentRow.indices.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }

    struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var maxHeight: CGFloat = 0

        mutating func add(index: Int, width: CGFloat, height: CGFloat, spacing: CGFloat) {
            if !indices.isEmpty {
                self.width += spacing
            }
            indices.append(index)
            self.width += width
            maxHeight = max(maxHeight, height)
        }
    }
}
