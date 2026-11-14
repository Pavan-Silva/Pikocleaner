//
//  ActivityRail.swift
//  PikoCleaner
//
//  Persistent vertical navigation rail shown beside every page.
//

import SwiftUI

/// A slim, always-visible navigation rail that replaces the old toolbar menu.
/// Each page gets an icon with a short label, a hover state, and a selected pill.
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
        CurrentPage.availablePages
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 3) {
                    ForEach(Array(pages.enumerated()), id: \.element) { index, page in
                        if page == .updater, index > 0 {
                            divider
                        }

                        railButton(for: page)
                    }
                }
                .padding(.horizontal, 8)
                // Clear the window traffic lights, matching the page sidebars.
                .padding(.top, 40)
                .padding(.bottom, 10)
            }

            divider
                .padding(.horizontal, 18)

            settingsButton
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
        }
        .frame(width: 78)
        .frame(maxHeight: .infinity)
        .background(railBackground)
    }

    // MARK: - Rail item

    private func railButton(for page: CurrentPage) -> some View {
        let isSelected = selection == page
        let isHovered = hoveredPage == page

        return Button {
            onSelect(page)
        } label: {
            VStack(spacing: 3) {
                Image(systemName: page.icon)
                    .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                    .frame(height: 19)
                    .overlay(alignment: .topTrailing) {
                        if page == .updater, updateCount > 0 {
                            Text(updateCount > 99 ? "99+" : "\(updateCount)")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Capsule().fill(Color.red))
                                .offset(x: 13, y: -7)
                        }
                    }

                Text(page.title)
                    .font(.system(size: 9, weight: isSelected ? .semibold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .allowsTightening(true)
            }
            .foregroundStyle(isSelected ? theme.accent : theme.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        isSelected
                            ? theme.accent.opacity(0.15)
                            : (isHovered ? theme.primaryText.opacity(0.07) : Color.clear)
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(page.title)
        .onHover { inside in
            withAnimation(.easeOut(duration: animationEnabled ? 0.12 : 0)) {
                hoveredPage = inside ? page : (hoveredPage == page ? nil : hoveredPage)
            }
        }
    }

    // MARK: - Settings

    private var settingsButton: some View {
        Button(action: onOpenSettings) {
            VStack(spacing: 3) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .regular))
                    .frame(height: 19)

                Text("Settings")
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(theme.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .help("Settings")
    }

    // MARK: - Chrome

    private var divider: some View {
        Rectangle()
            .fill(theme.primaryText.opacity(0.10))
            .frame(height: 1)
            .padding(.vertical, 3)
    }

    private var railBackground: some View {
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
