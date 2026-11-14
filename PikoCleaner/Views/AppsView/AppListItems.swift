//
//  AppListDetails.swift
//  PikoCleaner
//
//  Created by Alin Lupascu on 11/10/23.
//

import Foundation
import SwiftUI

struct AppListItems: View {
    @EnvironmentObject var appState: AppState
    @Binding var search: String
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("settings.general.glass") private var glass: Bool = true
    @AppStorage("settings.interface.minimalist") private var minimalEnabled: Bool = true
    @EnvironmentObject var locations: Locations
    let itemId = UUID()
    let appInfo: AppInfo
    var isSelected: Bool { appState.appInfo.path == appInfo.path }
    @Namespace var appItemNamespace

    var body: some View {

        HStack {

            Button(action: {
                if !isSelected {
                    showAppInFiles(appInfo: appInfo, appState: appState, locations: locations)
                } else {
                    // Closing the same item
                    updateOnMain {
                        appState.appInfo = .empty
                        appState.selectedItems = []
                        appState.currentView = .empty
                    }
                }

            }) {
                VStack {

                    HStack(alignment: .center, spacing: PageListMetrics.itemSpacing) {

                        if let appIcon = appInfo.appIcon {
                            ZStack {
                                Image(nsImage: appIcon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 36, height: 36)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .matchedGeometryEffect(
                                        id: "icon-\(appInfo.path.path)", in: appItemNamespace)
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: appInfo.appName)
                                .font(.system(size: isSelected ? 14 : 12))
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if minimalEnabled {
                                Text(
                                    appInfo.bundleSize == 0
                                        ? String(localized: "calculating")
                                        : formatByte(size: appInfo.bundleSize).human
                                )
                                .font(.system(size: 10))
                                .foregroundStyle(
                                    ThemeColors.shared(for: colorScheme).primaryText.opacity(0.5))
                                .lineLimit(1)
                                .truncationMode(.tail)
                            } else {
                                HStack(spacing: 5) {
                                    Text(verbatim: "v\(appInfo.appVersion)")
                                    Text(verbatim: "•")
                                    Text(
                                        appInfo.bundleSize == 0
                                            ? String(localized: "calculating")
                                            : formatByte(size: appInfo.bundleSize).human
                                    )
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                }
                                .font(.footnote)
                                .foregroundStyle(
                                    ThemeColors.shared(for: colorScheme).primaryText.opacity(0.5))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.000000001))
                .padding(.trailing, PageListMetrics.itemSpacing)
                .padding(.vertical, PageListMetrics.rowVerticalInset)
            }
            .contentShape(Rectangle())
            .buttonStyle(.plain)
            .foregroundStyle(ThemeColors.shared(for: colorScheme).primaryText)

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    isSelected && !glass ? ThemeColors.shared(for: colorScheme).secondaryBG : .clear
                )
        }
        .overlay {
            if isSelected {
                HStack {
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(ThemeColors.shared(for: colorScheme).accent)
                            .frame(width: 20, height: 20)
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .padding(.trailing, 7)
                }
                .allowsHitTesting(false)
            }
        }
        .onAppear {
            if appInfo.bundleSize == 0 {
                appState.getBundleSize(for: appInfo) { size in
                    //                    printOS("Getting size for: \(appInfo.appName)")
                    //                    appInfo.bundleSize = size
                }
            }
        }

    }

}
