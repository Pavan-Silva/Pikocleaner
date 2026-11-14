//
//  Searchbar.swift
//  PikoCleaner
//
//  Created by Alin Lupascu on 4/26/24.
//

import SwiftUI

struct AppSearchView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var locations: Locations
    @EnvironmentObject var fsm: FolderSettingsManager
    @EnvironmentObject var updater: Updater
    @Environment(\.colorScheme) var colorScheme
    @State private var search: String = ""
    @AppStorage("settings.general.selectedSortAppsList") var selectedSortOption: SortOption =
        .alphabetical
    @AppStorage("settings.interface.animationEnabled") private var animationEnabled: Bool = true

    var body: some View {

        VStack(alignment: .leading, spacing: 0) {
            PageHeaderView(
                title: "Apps",
                description: "Browse and clean installed applications"
            ) {
                HStack(spacing: 0) {
                    Button {
                        withAnimation(.easeInOut(duration: animationEnabled ? 0.3 : 0)) {
                            appState.isGridMode = false
                        }
                    } label: {
                        PageHeaderActionLabel(title: "List View", systemImage: appState.isGridMode ? "list.bullet.circle" : "list.bullet.circle.fill")
                    }
                    .help("List View")

                    Button {
                        withAnimation(.easeInOut(duration: animationEnabled ? 0.3 : 0)) {
                            appState.isGridMode = true
                        }
                    } label: {
                        PageHeaderActionLabel(title: "Grid View", systemImage: appState.isGridMode ? "square.grid.2x2.fill" : "square.grid.2x2")
                    }
                    .help("Grid View")

                    Button {
                        Task { @MainActor in
                            withAnimation(Animation.easeInOut(duration: animationEnabled ? 0.35 : 0)) {
                                loadApps(folderPaths: fsm.folderPaths)
                            }
                        }
                    } label: {
                        PageHeaderActionLabel(title: "Refresh List", systemImage: "arrow.counterclockwise")
                    }
                    .help("Refresh app list")

                }
            }

            if appState.sortedApps.isEmpty {
                VStack {
                    Spacer()
                    Text("No apps found")
                        .foregroundStyle(ThemeColors.shared(for: colorScheme).secondaryText)
                        .font(.callout)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                SearchBarSidebar(search: $search)
                    .padding(.horizontal, 20)
                    .padding(.top, 5)
                    .padding(.bottom, 16)

                if !filteredApps.isEmpty {
                    AppsListView(
                        search: $search, filteredApps: filteredApps, isGridMode: appState.isGridMode
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 5)
                } else {
                    VStack {
                        Spacer()
                        Text("No results")
                            .foregroundStyle(ThemeColors.shared(for: colorScheme).secondaryText)
                            .font(.title2)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }


            }
        }
        .pikoToolbarBackground()
    }

    private var filteredApps: [AppInfo] {
        let apps: [AppInfo]
        if search.isEmpty {
            apps = appState.sortedApps
        } else {
            // Use custom fuzzy search algorithm
            let searchResults = appState.sortedApps.fuzzySearch(query: search)
            apps = searchResults.map { $0.item }
        }

        // Sort based on the selected option
        switch selectedSortOption {
        case .alphabetical:
            return apps.sorted {
                $0.appName.replacingOccurrences(of: ".", with: "").sortKey
                    < $1.appName.replacingOccurrences(of: ".", with: "").sortKey
            }
        case .size:
            return apps.sorted { $0.bundleSize > $1.bundleSize }
        case .creationDate:
            return apps.sorted {
                ($0.creationDate ?? Date.distantPast) > ($1.creationDate ?? Date.distantPast)
            }
        case .dateAdded:
            return apps.sorted {
                ($0.dateAdded ?? Date.distantPast) > ($1.dateAdded ?? Date.distantPast)
            }
        case .contentChangeDate:
            return apps.sorted {
                ($0.contentChangeDate ?? Date.distantPast)
                    > ($1.contentChangeDate ?? Date.distantPast)
            }
        case .lastUsedDate:
            return apps.sorted {
                ($0.lastUsedDate ?? Date.distantPast) > ($1.lastUsedDate ?? Date.distantPast)
            }
        }

    }

}


struct SearchBarSidebar: View {
    @Binding var search: String
    @State var menu: Bool = true
    @State var padding: CGFloat = 5
    @State var sidebar: Bool = true
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack {
            TextField("Search...", text: $search)
                .textFieldStyle(SimpleSearchStyleSidebar(menu: menu, trash: true, text: $search))
        }
    }
}
