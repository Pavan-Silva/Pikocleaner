//
//  ActivityRail.swift
//  PikoCleaner
//
//  Persistent navigation sidebar shown beside every page.
//

import SwiftUI

/// A full-width navigation sidebar for switching between the app's main pages.
struct ActivityRail: View {
    @Binding var selection: CurrentPage
    var updateCount: Int = 0
    var onSelect: (CurrentPage) -> Void
    var onOpenSettings: () -> Void

    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("settings.interface.animationEnabled") private var animationEnabled: Bool = true
    @State private var hoveredPage: CurrentPage?

    private var theme: ThemeColors {
        ThemeColors.shared(for: colorScheme)
    }

    private var pages: [CurrentPage] {
        let availablePages = CurrentPage.availablePages
        guard availablePages.contains(.storage) else {
            return availablePages
        }

        return [.storage] + availablePages.filter { $0 != .storage }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 4) {
                    ForEach(pages) { page in
                        if page == .updater {
                            divider
                                .padding(.vertical, 6)
                        }

                        NavigationSidebarItem(
                            page: page,
                            isSelected: selection == page,
                            isHovered: hoveredPage == page,
                            updateCount: page == .updater ? updateCount : 0,
                            theme: theme,
                            action: { onSelect(page) }
                        )
                        .onHover { isInside in
                            withAnimation(.easeOut(duration: animationEnabled ? 0.12 : 0)) {
                                hoveredPage = isInside ? page : (hoveredPage == page ? nil : hoveredPage)
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 8)
                .padding(.bottom, 10)
            }

            divider
                .padding(.horizontal, 12)

            NavigationSidebarSettingsItem(theme: theme, action: onOpenSettings)
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
        }
        .frame(width: 210)
        .frame(maxHeight: .infinity)
        .background(sidebarBackground)
    }

    private var divider: some View {
        Rectangle()
            .fill(theme.primaryText.opacity(0.10))
            .frame(height: 1)
    }

    private var sidebarBackground: some View {
        ZStack(alignment: .trailing) {
            Rectangle()
                .fill(.ultraThinMaterial)

            Rectangle()
                .fill(theme.primaryText.opacity(colorScheme == .dark ? 0.14 : 0.08))
                .frame(width: 1)
        }
        .ignoresSafeArea(edges: .top)
    }
}

private struct NavigationSidebarItem: View {
    let page: CurrentPage
    let isSelected: Bool
    let isHovered: Bool
    let updateCount: Int
    let theme: ThemeColors
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: page.icon)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                    .frame(width: 20)

                Text(page.title)
                    .font(.body.weight(isSelected ? .semibold : .regular))

                Spacer(minLength: 0)

                if updateCount > 0 {
                    Text(updateCount > 99 ? "99+" : "\(updateCount)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.red))
                }
            }
            .foregroundStyle(isSelected ? theme.accent : theme.primaryText)
            .padding(.horizontal, 10)
            .frame(minHeight: 34)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(rowBackground)
            )
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(page.title)
    }

    private var rowBackground: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(theme.accent.opacity(0.15))
        }

        return AnyShapeStyle(isHovered ? theme.primaryText.opacity(0.07) : Color.clear)
    }
}

private struct NavigationSidebarSettingsItem: View {
    let theme: ThemeColors
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Settings", systemImage: "gearshape")
                .font(.body)
                .foregroundStyle(theme.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .frame(minHeight: 34)
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .help("Settings")
    }
}
