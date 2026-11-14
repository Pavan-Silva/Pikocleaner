//
//  Update.swift
//  Pearcleaner
//
//  Created by Alin Lupascu on 11/5/23.
//


import SwiftUI
import Foundation

struct UpdateSettingsTab: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var updater: Updater
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 20) {

            if ForkInfo.updatesConfigured {
                // === Frequency ============================================================================================
                PearGroupBox(header: { Text("Update Frequency").foregroundStyle(ThemeColors.shared(for: colorScheme).primaryText).font(.title2) }, content: {
                    FrequencyView(updater: updater)
                        .foregroundStyle(ThemeColors.shared(for: colorScheme).primaryText)
                })

                // === Release Notes ========================================================================================
                PearGroupBox(header: { Text("Release Notes").foregroundStyle(ThemeColors.shared(for: colorScheme).primaryText).font(.title2) }, content: {
                    RecentReleasesView(updater: updater)
                        .frame(height: 380)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(ThemeColors.shared(for: colorScheme).primaryText)
                })

                // === Buttons ==============================================================================================

                HStack(alignment: .center, spacing: 20) {

                    Button {
                        updater.checkForUpdates(sheet: true, force: true)
                    } label: {
                        Label("Refresh", systemImage: "arrow.uturn.left.circle")
                    }
                        .buttonStyle(ControlGroupButtonStyle(foregroundColor: ThemeColors.shared(for: colorScheme).primaryText, shape: .capsule))


                    Button {
                        updater.resetAnnouncementAlert()
                    } label: {
                        Label("Announcement", systemImage: "star")
                    }
                        .buttonStyle(ControlGroupButtonStyle(foregroundColor: ThemeColors.shared(for: colorScheme).primaryText, shape: .capsule))
                        .sheet(isPresented: $updater.showAnnouncementSheet, content: {
                            updater.getAnnouncementView()
                        })


                    if let releasesURL = ForkInfo.releasesURL {
                        Button {
                            ForkInfo.open(releasesURL)
                        } label: {
                            Label("Releases", systemImage: "link")
                        }
                            .buttonStyle(ControlGroupButtonStyle(foregroundColor: ThemeColors.shared(for: colorScheme).primaryText, shape: .capsule))
                    }

                }
            } else {
                PearGroupBox(header: { Text("Updates").foregroundStyle(ThemeColors.shared(for: colorScheme).primaryText).font(.title2) }, content: {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Self-updates are not configured for this build.")
                            .font(.title3)
                            .foregroundStyle(ThemeColors.shared(for: colorScheme).primaryText)
                        Text("Set repoOwner and repoName in ForkInfo.swift to enable update checks, announcements and release notes.")
                            .font(.callout)
                            .foregroundStyle(ThemeColors.shared(for: colorScheme).secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                })
            }

        }

    }
    
}
