//
//  ForkInfo.swift
//  Pearcleaner
//
//  Central configuration for this fork. Fill in your own GitHub owner and
//  repository name to enable self-updates and repository links; while they are
//  empty the app makes no update/announcement network requests.
//

import AppKit
import Foundation

enum ForkInfo {
    static let name = "Pearcleaner"

    // MARK: - Repository configuration

    /// GitHub account that owns this fork.
    static let repoOwner = ""

    /// GitHub repository name for this fork.
    static let repoName = ""

    static var updatesConfigured: Bool {
        !repoOwner.isEmpty && !repoName.isEmpty
    }

    static var repoURL: URL? {
        guard updatesConfigured else { return nil }
        return URL(string: "https://github.com/\(repoOwner)/\(repoName)")
    }

    static var releasesURL: URL? {
        repoURL?.appendingPathComponent("releases")
    }

    static var issuesURL: URL? {
        repoURL?.appendingPathComponent("issues")
    }

    static var newIssueURL: URL? {
        issuesURL?.appendingPathComponent("new/choose")
    }

    // MARK: - Operating system chrome

    /// macOS 27 Golden Gate uses edge-to-edge sidebars and uniform toolbars.
    /// Keep the custom Tahoe-era glass chrome only on older systems.
    static var usesGoldenGateChrome: Bool {
        if #available(macOS 27.0, *) {
            return true
        }
        return false
    }

    // MARK: - Helpers

    static func open(_ url: URL?) {
        guard let url else { return }
        NSWorkspace.shared.open(url)
    }
}
