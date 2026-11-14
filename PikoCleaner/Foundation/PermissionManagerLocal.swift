//
//  PermissionManagerLocal.swift
//  PikoCleaner
//
//  Tracks the macOS privacy permissions the app needs and drives the single
//  bottom-right permission prompt.
//

import AppKit
import Foundation

class PermissionManagerLocal: ObservableObject {
    static let shared = PermissionManagerLocal()

    @Published private(set) var results: PermissionsCheckResults?

    /// Whether the single permission prompt is currently visible.
    @Published private(set) var promptVisible: Bool = false

    /// Auto-present the prompt only once per "missing" episode so dismissing it
    /// does not make it pop back up on every check.
    private var didAutoPresent: Bool = false

    private init() {}

    var allPermissionsGranted: Bool {
        return results?.fullDiskAccess ?? false
    }

    /// Returns true when the permission check is complete AND access is denied.
    /// Use this for UI warnings/badges to avoid false positives before the check completes.
    var shouldShowPermissionWarning: Bool {
        guard let results = results else {
            return false
        }
        return results.fullDiskAccess == false
    }

    enum PermissionType {
        case fullDiskAccess
    }

    struct PermissionsCheckResults {
        var fullDiskAccess: Bool?

        var checkedPermissions: [PermissionType] {
            return fullDiskAccess != nil ? [.fullDiskAccess] : []
        }

        var grantedPermissions: [PermissionType] {
            return fullDiskAccess == true ? [.fullDiskAccess] : []
        }
    }

    // MARK: - Prompt state

    func updateResults(_ newResults: PermissionsCheckResults) {
        results = newResults

        if newResults.fullDiskAccess == false {
            if !didAutoPresent {
                didAutoPresent = true
                promptVisible = true
            }
        } else if newResults.fullDiskAccess == true {
            // A later revocation should be able to prompt again. Leave the
            // prompt visible so an open card can flip to its success state.
            didAutoPresent = false
        }
    }

    /// Shows the prompt from an explicit user action (toolbar, Settings, deep link).
    func presentPrompt(activate: Bool = true) {
        promptVisible = true

        guard activate else { return }

        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows
            .first { $0.isVisible && !$0.isSheet && !WindowManager.shared.isManaged($0) }?
            .makeKeyAndOrderFront(nil)
    }

    func dismissPrompt() {
        promptVisible = false
    }

    func refresh() {
        checkPermissions(types: [.fullDiskAccess]) { [weak self] results in
            self?.updateResults(results)
        }
    }

    func openSystemSettings() {
        let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Checks

    func checkPermissions(types: [PermissionType] = [.fullDiskAccess], completion: @escaping (PermissionsCheckResults) -> Void) {
        checkFullDiskAccess { hasAccess in
            let results = PermissionsCheckResults(fullDiskAccess: hasAccess)
            completion(results)
        }
    }

    /// Check Full Disk Access permission with retry logic.
    /// Uses higher priority QoS and faster syscall for better reliability.
    private func checkFullDiskAccess(completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {  // Higher priority than .background
            let result = self.attemptFDACheck(maxAttempts: 2, delayMs: 100)
            DispatchQueue.main.async {
                if !result {
                    printOS("Full Disk Permission: ❌")
                }
                completion(result)
            }
        }
    }

    /// Attempt FDA check with retries and multiple fallback paths.
    /// First tries the fast access() syscall, then falls back to directory listing.
    private func attemptFDACheck(maxAttempts: Int, delayMs: Int) -> Bool {
        // Multiple protected paths to check, in order of preference
        let checkPaths = [
            "~/Library/Containers/com.apple.stocks",  // Primary - good for macOS 12+
            "~/Library/Safari",                        // Fallback 1 - more universal
            "~/Library/Mail"                           // Fallback 2 - additional option
        ]

        for attempt in 1...maxAttempts {
            // Try each path
            for checkPath in checkPaths {
                let expandedPath = NSString(string: checkPath).expandingTildeInPath

                // Method 1: Try using access() syscall (fastest)
                if let cPath = expandedPath.cString(using: .utf8) {
                    if access(cPath, R_OK) == 0 {
                        return true  // Success - have FDA
                    }
                }

                // Method 2: Fallback to directory listing (more reliable but slower)
                let fileManager = FileManager.default
                if let _ = try? fileManager.contentsOfDirectory(atPath: expandedPath) {
                    return true
                }
            }

            // If not last attempt, wait before retry
            if attempt < maxAttempts {
                Thread.sleep(forTimeInterval: Double(delayMs) / 1000.0)
            }
        }

        return false  // All attempts and all paths failed
    }
}
