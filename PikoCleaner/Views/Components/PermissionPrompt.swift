//
//  PermissionPrompt.swift
//  PikoCleaner
//
//  The single permission prompt shown in the bottom-right corner of the main
//  window. Replaces the former toolbar sheet, Settings sheet and deep-link
//  window so permission guidance only ever appears in one place.
//

import AppKit
import SwiftUI

struct PermissionPrompt: View {
    @ObservedObject private var permissions = PermissionManagerLocal.shared

    private var isGranted: Bool {
        permissions.allPermissionsGranted
    }

    var body: some View {
        if permissions.promptVisible {
            card
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if !isGranted {
                message
            }

            statusRow
            actions
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
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            // Re-check when the user returns from System Settings.
            permissions.refresh()
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: isGranted ? "checkmark.shield" : "lock.shield")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.secondary)

            Text(isGranted ? "Permission Status" : "Missing Permissions")
                .font(.headline)

            Spacer(minLength: 12)

            Button {
                permissions.dismissPrompt()
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

    private var message: some View {
        Text("PikoCleaner requires permissions to search all system locations comprehensively.")
            .font(.callout)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var statusRow: some View {
        HStack(spacing: 10) {
            Image(systemName: isGranted ? "checkmark.circle" : "exclamationmark.circle")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.secondary)

            Text("Full Disk Access")
                .font(.callout)

            Spacer(minLength: 8)

            if isGranted {
                Text("Enabled")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @ViewBuilder
    private var actions: some View {
        HStack(spacing: 8) {
            if isGranted {
                Spacer(minLength: 0)

                Button("Close") {
                    permissions.dismissPrompt()
                }
                .controlSize(.small)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            } else {
                Button("Retry") {
                    permissions.refresh()
                }
                .controlSize(.small)

                Spacer(minLength: 0)

                Button("Open System Settings") {
                    permissions.openSystemSettings()
                }
                .controlSize(.small)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
    }
}
