//
//  ExpandableActionButton.swift
//  PikoCleaner
//
//  Created by Alin Lupascu on 11/25/25.
//

import SwiftUI

struct ExpandableActionButton: View {
    let primaryAction: ActionButtonItem
    let secondaryActions: [ActionButtonItem]
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 0) {
            Button(action: primaryAction.action) {
                Text(primaryAction.title)
                    .font(.callout.weight(.medium))
            }
            .buttonStyle(ControlGroupButtonStyle(
                foregroundColor: primaryAction.foregroundColor,
                shape: Capsule(style: .continuous),
                level: .primary,
                verticalPadding: 8,
                horizontalPadding: 12,
                skipControlGroup: true
            ))
            .disabled(primaryAction.isDisabled)

            if !secondaryActions.isEmpty {
                Menu {
                    ForEach(Array(secondaryActions.enumerated()), id: \.offset) { _, item in
                        Button {
                            item.action()
                        } label: {
                            Text(item.title)
                                .foregroundStyle(item.foregroundColor)
                        }
                        .disabled(item.isDisabled)
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .frame(width: 24, height: 24)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .buttonStyle(ControlGroupButtonStyle(
                    foregroundColor: ThemeColors.shared(for: colorScheme).secondaryText,
                    shape: Capsule(style: .continuous),
                    level: .primary,
                    verticalPadding: 8,
                    horizontalPadding: 6,
                    skipControlGroup: true
                ))
            }
        }
        .controlGroup(Capsule(style: .continuous), level: .primary)
        .opacity(primaryAction.isDisabled ? 0.5 : 1.0)
    }
}

struct ActionButtonItem {
    let title: String
    let foregroundColor: Color
    let isDisabled: Bool
    let action: () -> Void

    init(
        title: String,
        foregroundColor: Color,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.foregroundColor = foregroundColor
        self.isDisabled = isDisabled
        self.action = action
    }

}
