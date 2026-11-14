//
//  DaemonView.swift
//  PikoCleaner
//
//  Created by Alin Lupascu on 11/5/23.
//

import SwiftUI

struct DaemonView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var consoleManager = GlobalConsoleManager.shared
    @State private var launchItems: [LaunchItem] = []
    @State private var isLoading: Bool = false
    @State private var searchText: String = ""
    @State private var selectedFilter: LaunchItemFilter = .all
    @State private var lastRefreshDate: Date?
    @AppStorage("settings.interface.scrollIndicators") private var scrollIndicators: Bool = false
    @AppStorage("settings.interface.animationEnabled") private var animationEnabled: Bool = true

    private enum LaunchItemFilter: String, CaseIterable {
        case all = "All"
        case loaded = "Loaded"
        case unloaded = "Unloaded"
        case running = "Running"
        case agents = "Agents"
        case daemons = "Daemons"
        case services = "Services"

        var systemImage: String {
            switch self {
            case .all: return "list.bullet"
            case .loaded: return "checkmark.circle"
            case .unloaded: return "xmark.circle"
            case .running: return "play.circle"
            case .agents: return "person.circle"
            case .daemons: return "gear.circle"
            case .services: return "network"
            }
        }
    }

    private var filteredItems: [LaunchItem] {
        var items = launchItems.filter { !$0.label.hasPrefix("com.apple.") }

        // Apply search filter
        if !searchText.isEmpty {
            items = items.filter { item in
                item.label.localizedCaseInsensitiveContains(searchText) ||
                item.path.localizedCaseInsensitiveContains(searchText) ||
                (item.bundlePath?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Apply type/status filter
        switch selectedFilter {
        case .all:
            return items
        case .loaded:
            return items.filter { isItemLoaded($0) }
        case .unloaded:
            return items.filter { !isItemLoaded($0) }
        case .running:
            return items.filter { isItemRunning($0) }
        case .agents:
            return items.filter { $0.type == .agent }
        case .daemons:
            return items.filter { $0.type == .daemon }
        case .services:
            return items.filter { $0.type == .service }
        }
    }

    private func isItemLoaded(_ item: LaunchItem) -> Bool {
        // Simple logic: if status is "Not Loaded", it's not loaded
        // If it has any other status, it was found in launchctl list and is loaded
        return item.status != "Not Loaded"
    }

    private func isItemRunning(_ item: LaunchItem) -> Bool {
        // An item is running if it's loaded AND has a PID (same logic as friendlyStatus)
        if item.status == "Not Loaded" {
            return false
        }

        if let statusCode = Int(item.status), statusCode == 0 {
            return item.pid != nil && item.pid != "-" && !item.pid!.isEmpty
        }

        return false
    }

    private func friendlyStatus(for item: LaunchItem) -> String {
        // Handle our custom "Not Loaded" status first
        if item.status == "Not Loaded" {
            return "Not Loaded"
        }

        // Check if it's a numeric status code
        if let statusCode = Int(item.status) {
            switch statusCode {
            case 0:
                // If it has a PID, it's running, otherwise it's just loaded but not active
                if item.pid != nil && item.pid != "-" && !item.pid!.isEmpty {
                    return "Running"
                } else {
                    return "Loaded"
                }
            case -1:
                return "Error (Exit -1)"
            case -2:
                return "Error (Exit -2)"
            case -3:
                return "Error (Exit -3)"
            default:
                if statusCode > 0 {
                    return "Error (Exit \(statusCode))"
                } else {
                    return "Error (\(statusCode))"
                }
            }
        }

        // Handle text status (shouldn't happen with new logic, but just in case)
        return item.status.capitalized
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            PageHeaderView(
                title: "Launch Services Manager",
                description: "Manage launch agents, daemons, and XPC services"
            ) {
                HStack(spacing: 0) {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            consoleManager.showConsole.toggle()
                        }
                    } label: {
                        PageHeaderActionLabel(title: "Console", systemImage: consoleManager.showConsole ? "terminal.fill" : "terminal")
                    }
                    .help("Toggle console output")

                    Menu {
                        ForEach(LaunchItemFilter.allCases, id: \.self) { filter in
                            Button {
                                selectedFilter = filter
                            } label: {
                                Label(filter.rawValue, systemImage: filter.systemImage)
                            }
                        }
                    } label: {
                        PageHeaderActionLabel(title: selectedFilter.rawValue, systemImage: selectedFilter.systemImage)
                    }
                    .menuIndicator(.hidden)
                    .help("Filter by \(selectedFilter.rawValue)")

                    Button {
                        refreshLaunchItems()
                    } label: {
                        PageHeaderActionLabel(title: "Refresh", systemImage: "arrow.counterclockwise")
                    }
                    .disabled(isLoading)
                    .help("Refresh launch services")
                }
            }

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(ThemeColors.shared(for: colorScheme).secondaryText)

                TextField("Search...", text: $searchText)
                    .textFieldStyle(.plain)
                    .foregroundStyle(ThemeColors.shared(for: colorScheme).primaryText)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(ThemeColors.shared(for: colorScheme).secondaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(ThemeColors.shared(for: colorScheme).accent)
            .controlGroup(Capsule(style: .continuous), level: .primary)
            .padding(.horizontal, 20)

            if isLoading {
                VStack(alignment: .center, spacing: 10) {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading launch services...")
                        .font(.title2)
                        .foregroundStyle(ThemeColors.shared(for: colorScheme).secondaryText)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else if filteredItems.isEmpty {
                VStack(alignment: .center) {
                    Spacer()
                    Image(systemName: selectedFilter.systemImage)
                        .font(.system(size: 48))
                        .foregroundStyle(ThemeColors.shared(for: colorScheme).secondaryText)
                    Text(launchItems.isEmpty ? "No launch services found" : "No items match the current filters")
                        .font(.title2)
                        .foregroundStyle(ThemeColors.shared(for: colorScheme).secondaryText)
                    if !searchText.isEmpty {
                        Text("Try adjusting your search or filters")
                            .font(.caption)
                            .foregroundStyle(ThemeColors.shared(for: colorScheme).secondaryText)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {

                // Stats header
                HStack {
                    Text("\(filteredItems.count) service\(filteredItems.count == 1 ? "" : "s")")
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(ThemeColors.shared(for: colorScheme).secondaryText)

                    if selectedFilter == .all && !launchItems.isEmpty {
                        let loadedCount = filteredItems.filter { isItemLoaded($0) }.count
                        let unloadedCount = filteredItems.count - loadedCount

                        Text(verbatim: "•")
                            .foregroundStyle(ThemeColors.shared(for: colorScheme).secondaryText)

                        Text("\(loadedCount) loaded")
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(.blue)

                        Text(verbatim: "•")
                            .foregroundStyle(ThemeColors.shared(for: colorScheme).secondaryText)

                        Text("\(unloadedCount) not loaded")
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(ThemeColors.shared(for: colorScheme).secondaryText)
                    }

                    Spacer()

                    if let lastRefresh = lastRefreshDate {
                        TimelineView(.periodic(from: lastRefresh, by: 60.0)) { timeline in
                            Group {
                                if timeline.date.timeIntervalSince(lastRefresh) < 60 {
                                    Text("Updated now")
                                } else {
                                    Text("Updated \(formatRelativeTime(lastRefresh))")
                                }
                            }
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(ThemeColors.shared(for: colorScheme).secondaryText)
                        }
                    }
                }
                .padding(.vertical)
                .padding(.horizontal, 20)

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(filteredItems.enumerated()), id: \.offset) { index, item in
                            LaunchItemRowView(item: item) {
                                refreshLaunchItems()
                            }

                            if index < filteredItems.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
                .scrollIndicators(scrollIndicators ? .automatic : .never)
                .padding(.horizontal, 20)
            }

//            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if launchItems.isEmpty {
                refreshLaunchItems()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DaemonViewShouldRefresh"))) { _ in
            refreshLaunchItems()
        }
        .pikoToolbarBackground()
    }

    private func refreshLaunchItems() {
        GlobalConsoleManager.shared.appendOutput("Refreshing launch services...\n", source: CurrentPage.services.title)
        isLoading = true

        Task {
            let result = await Task.detached(priority: .utility) {
                Self.loadLaunchItemsSynchronously()
            }.value

            await MainActor.run {
                if let error = result.error {
                    GlobalConsoleManager.shared.appendOutput("Error loading launch services: \(error)\n", source: CurrentPage.services.title)
                }

                let items = result.items
                self.launchItems = items.sorted { first, second in
                    return first.label.localizedCaseInsensitiveCompare(second.label) == .orderedAscending
                }
                self.lastRefreshDate = Date()
                self.isLoading = false
                GlobalConsoleManager.shared.appendOutput("✓ Loaded \(items.count) launch services\n", source: CurrentPage.services.title)
            }
        }
    }

    private nonisolated static func loadLaunchItemsSynchronously() -> (items: [LaunchItem], error: String?) {
        var items: [LaunchItem] = []
        var loadError: String?

        // Use launchctl to list all services
        let process = Process()
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["list"]

        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: .newlines)
                // Skip header line
                for line in lines.dropFirst() {
                    let components = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                    if components.count >= 3 {
                        let pid = components[0]
                        let status = components[1]
                        let label = components[2]

                        // Skip if label is empty
                        if label.isEmpty { continue }

                        // Determine type
                        var type: LaunchItemType = .agent
                        if label.hasPrefix("com.apple.") {
                            type = .system
                        } else if label.contains(".daemon") || label.contains("LaunchDaemon") {
                            type = .daemon
                        } else if label.contains(".service") {
                            type = .service
                        }

                        items.append(LaunchItem(
                            id: label,
                            label: label,
                            pid: pid == "-" ? nil : pid,
                            status: status,
                            type: type,
                            path: "",
                            bundlePath: nil
                        ))
                    }
                }
            }
        } catch {
            loadError = error.localizedDescription
        }

        // Also load from LaunchAgents and LaunchDaemons directories
        let paths = [
            "/Library/LaunchAgents",
            "/Library/LaunchDaemons",
            "/System/Library/LaunchAgents",
            "/System/Library/LaunchDaemons",
            NSHomeDirectory() + "/Library/LaunchAgents"
        ]
        var knownLabels = Set(items.map(\.label))

        for path in paths {
            let url = URL(fileURLWithPath: path)
            if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey]) {
                while let fileURL = enumerator.nextObject() as? URL {
                    if fileURL.pathExtension == "plist" {
                        let label = fileURL.deletingPathExtension().lastPathComponent
                        guard knownLabels.insert(label).inserted else { continue }

                        var type: LaunchItemType = .agent
                        if path.contains("LaunchDaemons") {
                            type = .daemon
                        }

                        items.append(LaunchItem(
                            id: label,
                            label: label,
                            pid: nil,
                            status: "Not Loaded",
                            type: type,
                            path: fileURL.path,
                            bundlePath: nil
                        ))
                    }
                }
            }
        }

        return (items, loadError)
    }

    private func formatRelativeTime(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "\(Int(interval))s ago"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else {
            return "\(Int(interval / 3600))h ago"
        }
    }
}

struct LaunchItem: Identifiable, Sendable {
    let id: String
    let label: String
    let pid: String?
    let status: String
    let type: LaunchItemType
    let path: String
    let bundlePath: String?
}

enum LaunchItemType: Sendable {
    case agent
    case daemon
    case service
    case system
}

struct LaunchItemRowView: View {
    let item: LaunchItem
    let onRefresh: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var showDetail = false
    @State private var isLoading = false

    var body: some View {
        HStack(alignment: .center, spacing: PageListMetrics.itemSpacing) {
            Image(systemName: typeIcon)
                .font(.system(size: 24))
                .foregroundStyle(ThemeColors.shared(for: colorScheme).secondaryText)
                .frame(width: PageListMetrics.iconSize, height: PageListMetrics.iconSize)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.label)
                        .font(.title3)
                        .foregroundStyle(ThemeColors.shared(for: colorScheme).primaryText)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .help(item.label)

                    Text(friendlyStatus)
                        .font(.caption)
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.12), in: Capsule())
                    if let pid = item.pid {
                        Text("PID \(pid)")
                            .font(.caption)
                            .foregroundStyle(ThemeColors.shared(for: colorScheme).secondaryText)
                    }
                }

                if let path = item.bundlePath, !path.isEmpty {
                    Text(path)
                        .font(.footnote)
                        .foregroundStyle(ThemeColors.shared(for: colorScheme).secondaryText)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(path)
                } else if !item.path.isEmpty {
                    Text(item.path)
                        .font(.footnote)
                        .foregroundStyle(ThemeColors.shared(for: colorScheme).secondaryText)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(item.path)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 32, height: 32)
            } else {
                HStack(spacing: 0) {
                    if item.status != "Not Loaded" {
                        Button {
                            Task {
                                isLoading = true
                                let process = Process()
                                process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
                                process.arguments = ["stop", item.label]
                                try? process.run()
                                process.waitUntilExit()
                                await MainActor.run {
                                    isLoading = false
                                    onRefresh()
                                }
                            }
                        } label: {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 14))
                        }
                        .buttonStyle(ControlGroupButtonStyle(
                            foregroundColor: .red,
                            shape: Capsule(style: .continuous),
                            level: .primary,
                            verticalPadding: 8,
                            horizontalPadding: 9,
                            skipControlGroup: true
                        ))
                        .help("Stop service")
                        .accessibilityLabel("Stop service")

                        Button {
                            Task {
                                isLoading = true
                                let process = Process()
                                process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
                                process.arguments = ["start", item.label]
                                try? process.run()
                                process.waitUntilExit()
                                await MainActor.run {
                                    isLoading = false
                                    onRefresh()
                                }
                            }
                        } label: {
                            Image(systemName: "play.fill")
                                .font(.system(size: 14))
                        }
                        .buttonStyle(ControlGroupButtonStyle(
                            foregroundColor: .green,
                            shape: Capsule(style: .continuous),
                            level: .primary,
                            verticalPadding: 8,
                            horizontalPadding: 9,
                            skipControlGroup: true
                        ))
                        .help("Start service")
                        .accessibilityLabel("Start service")
                    } else if !item.path.isEmpty {
                        Button {
                            Task {
                                isLoading = true
                                let process = Process()
                                process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
                                process.arguments = ["load", item.path]
                                try? process.run()
                                process.waitUntilExit()
                                await MainActor.run {
                                    isLoading = false
                                    onRefresh()
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.down.to.line")
                                .font(.system(size: 14))
                        }
                        .buttonStyle(ControlGroupButtonStyle(
                            foregroundColor: ThemeColors.shared(for: colorScheme).accent,
                            shape: Capsule(style: .continuous),
                            level: .primary,
                            verticalPadding: 8,
                            horizontalPadding: 9,
                            skipControlGroup: true
                        ))
                        .help("Load service")
                        .accessibilityLabel("Load service")
                    }

                    Button {
                        showDetail.toggle()
                    } label: {
                        Image(systemName: "info")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .buttonStyle(ControlGroupButtonStyle(
                        foregroundColor: ThemeColors.shared(for: colorScheme).secondaryText,
                        shape: Capsule(style: .continuous),
                        level: .primary,
                        verticalPadding: 8,
                        horizontalPadding: 9,
                        skipControlGroup: true
                    ))
                    .help("Service details")
                    .accessibilityLabel("Service details")
                }
                .controlGroup(Capsule(style: .continuous), level: .primary)
                .popover(isPresented: $showDetail) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Service Details")
                            .font(.headline)
                        Divider()
                        DaemonDetailRow(label: "Label", value: item.label)
                        DaemonDetailRow(label: "Type", value: "\(item.type)")
                        DaemonDetailRow(label: "Status", value: friendlyStatus)
                        if let pid = item.pid {
                            DaemonDetailRow(label: "PID", value: pid)
                        }
                        if !item.path.isEmpty {
                            DaemonDetailRow(label: "Path", value: item.path)
                        }
                        if let bundlePath = item.bundlePath, !bundlePath.isEmpty {
                            DaemonDetailRow(label: "Bundle", value: bundlePath)
                        }
                    }
                    .padding(20)
                    .frame(width: 400)
                }
            }
        }
        .padding(.vertical, PageListMetrics.rowVerticalInset)
    }

    private var typeIcon: String {
        switch item.type {
        case .agent:
            return "person.crop.circle"
        case .daemon:
            return "gearshape.2.fill"
        case .service:
            return "network"
        case .system:
            return "gearshape.fill"
        }
    }

    private var friendlyStatus: String {
        if item.status == "Not Loaded" {
            return "Not Loaded"
        }

        if let statusCode = Int(item.status) {
            switch statusCode {
            case 0:
                if item.pid != nil && item.pid != "-" && !item.pid!.isEmpty {
                    return "Running"
                } else {
                    return "Loaded"
                }
            case -1: return "Error (Exit -1)"
            case -2: return "Error (Exit -2)"
            case -3: return "Error (Exit -3)"
            default:
                if statusCode > 0 {
                    return "Error (Exit \(statusCode))"
                } else {
                    return "Error (\(statusCode))"
                }
            }
        }
        return item.status.capitalized
    }

    private var statusColor: Color {
        if friendlyStatus == "Running" { return .green }
        if friendlyStatus == "Loaded" { return .blue }
        if friendlyStatus == "Not Loaded" { return ThemeColors.shared(for: colorScheme).secondaryText }
        return .red
    }
}

struct DaemonDetailRow: View {
    let label: String
    let value: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .foregroundStyle(ThemeColors.shared(for: colorScheme).secondaryText)
                .frame(width: 60, alignment: .leading)
            Text(value)
                .font(.caption)
                .foregroundStyle(ThemeColors.shared(for: colorScheme).primaryText)
            Spacer()
        }
    }
}