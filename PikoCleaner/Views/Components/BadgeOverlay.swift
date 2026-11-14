//
//  BadgeOverlay.swift
//  PikoCleaner
//
//  Bottom-right notification card for helper, update and announcement badges.
//  Permission guidance lives in PermissionPrompt so it only ever appears in
//  one place.
//
//  Created by Alin Lupascu on 10/23/25.
//

import SwiftUI

enum OverlayType {
    case helper
    case update
    case announcement
}

struct BadgeOverlay: View {
    @EnvironmentObject var updater: Updater
    @ObservedObject var helperManager = HelperToolManager.shared
    @AppStorage("settings.interface.badgeOverlaysEnabled") private var badgeOverlaysEnabled: Bool = true
    @State private var isExpanded: Bool = false
    @State private var appeared: Bool = false
    @State private var showUpdateView: Bool = false
    @State private var showFeatureView: Bool = false
    @State private var dismissedOverlays: Set<OverlayType> = []

    // Determine which overlay to show based on priority (helper → update → announcement)
    private var currentOverlay: OverlayType? {
        if helperManager.shouldShowHelperBadge && !dismissedOverlays.contains(.helper) {
            return .helper
        }

        if updater.updateAvailable && !dismissedOverlays.contains(.update) {
            return .update
        }

        if updater.announcementAvailable && !dismissedOverlays.contains(.announcement) {
            return .announcement
        }

        return nil
    }

    var body: some View {
        if badgeOverlaysEnabled, let overlay = currentOverlay {
            VStack(alignment: .leading, spacing: 14) {
                header(for: overlay)

                if isExpanded {
                    details(for: overlay)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Divider()

                actions(for: overlay)
            }
            .padding(16)
            .frame(width: 400)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color(nsColor: .separatorColor).opacity(0.7), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.18), radius: 16, y: 6)
            .accessibilityElement(children: .contain)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
            .onAppear {
                withAnimation(.easeOut(duration: 0.2)) {
                    appeared = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .helperRequired)) { _ in
                // Re-show the helper card when something actually needs the helper.
                dismissedOverlays.remove(.helper)
            }
            .onChange(of: currentOverlay) { _ in
                isExpanded = false
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Header

    private func header(for overlay: OverlayType) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: icon(for: overlay))
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.secondary)

            Text(title(for: overlay))
                .font(.headline)

            Spacer(minLength: 12)

            Button {
                dismissOverlay()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .help("Dismiss")
            .accessibilityLabel("Dismiss")
        }
    }

    // MARK: - Details

    @ViewBuilder
    private func details(for overlay: OverlayType) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()

            switch overlay {
            case .helper:
                Text("When the helper tool was introduced March 2025, it was said that AuthorizationExecuteWithPrivileges (granting authentication via password prompt popup) would eventually be removed as it has already been deprecated by Apple. Some functionality will stop working in PikoCleaner if the helper isn't enabled going forward.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Some of the features that require the helper:")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    helperFeature("Delete system-protected files and folders")
                    helperFeature("Unload launch daemons and agents")
                    helperFeature("Manage PKG receipts and installations")
                    helperFeature("Perform updates on 3rd party apps, and more")
                }

            case .update:
                Text("A new version of PikoCleaner is available for download.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

            case .announcement:
                Text("Check out the latest additions to PikoCleaner.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func helperFeature(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 7) {
            Text(verbatim: "•")
            Text(text)
        }
        .font(.callout)
        .foregroundStyle(.secondary)
    }

    // MARK: - Actions

    @ViewBuilder
    private func actions(for overlay: OverlayType) -> some View {
        HStack(spacing: 8) {
            switch overlay {
            case .helper:
                Button("Enable Helper") {
                    openAppSettingsWindow(tab: .helper, updater: updater)
                }
                .buttonStyle(.borderedProminent)
                .help("Open Settings to enable the Privileged Helper")

            case .update:
                Button("View Update") {
                    showUpdateView.toggle()
                }
                .buttonStyle(.borderedProminent)
                .help("View update details and download")
                .sheet(isPresented: $showUpdateView) {
                    updater.getUpdateView()
                }

            case .announcement:
                Button("Learn More") {
                    showFeatureView.toggle()
                }
                .buttonStyle(.borderedProminent)
                .help("View announcement details")
                .sheet(isPresented: $showFeatureView) {
                    updater.getAnnouncementView()
                }
            }

            Spacer(minLength: 0)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                Label(
                    isExpanded ? "See less" : "See more",
                    systemImage: isExpanded ? "chevron.up" : "chevron.down"
                )
            }
            .buttonStyle(.link)
            .font(.caption)
            .foregroundStyle(.secondary)
            .help(isExpanded ? "Hide details" : "Show details")
        }
        .controlSize(.small)
    }

    // MARK: - Overlay metadata

    private func icon(for overlay: OverlayType) -> String {
        switch overlay {
        case .helper:
            return "exclamationmark.triangle"
        case .update:
            return "arrow.down.circle"
        case .announcement:
            return "sparkles"
        }
    }

    private func title(for overlay: OverlayType) -> String {
        switch overlay {
        case .helper:
            return "Privileged Helper Not Installed!"
        case .update:
            return "Update Available!"
        case .announcement:
            return "New Feature!"
        }
    }

    // MARK: - Dismissal

    private func dismissOverlay() {
        guard let overlay = currentOverlay else { return }

        withAnimation(.easeOut(duration: 0.2)) {
            _ = dismissedOverlays.insert(overlay)
        }
    }
}
