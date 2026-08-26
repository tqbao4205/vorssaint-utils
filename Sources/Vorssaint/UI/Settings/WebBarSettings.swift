// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import SwiftUI

struct WebBarSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var service = WebBarService.shared
    @AppStorage(DefaultsKey.webBarShowOnMenuBar) private var showOnMenuBar = true
    @AppStorage(DefaultsKey.webBarAutoPause) private var autoPause = true
    @AppStorage(DefaultsKey.webBarAdBlock) private var adBlock = true
    @AppStorage(DefaultsKey.webBarNotificationsEnabled) private var notificationsEnabled = true
    @AppStorage(DefaultsKey.webBarNotificationBadges) private var notificationBadges = true
    @AppStorage(DefaultsKey.webBarNotificationSound) private var notificationSound = true

    private var strings: WebBarFeatureStrings { FeatureStrings.webBar(l10n.language) }

    var body: some View {
        Form {
            Section {
                Button {
                    service.show()
                } label: {
                    Label(strings.openButton, systemImage: "globe")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Text(strings.panelCaption)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Toggle(strings.showOnMenuBar, isOn: $showOnMenuBar)
                    .onChange(of: showOnMenuBar) { _, _ in
                        service.syncWithPreferences()
                    }
            } header: {
                Text(strings.pageTitle)
            }

            Section {
                Toggle(strings.notificationsToggle, isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { _, isEnabled in
                        if isEnabled {
                            WebBarNotificationManager.shared.requestAuthorization()
                        }
                    }

                Toggle(strings.notificationBadgesToggle, isOn: $notificationBadges)
                    .disabled(!notificationsEnabled)
                    .onChange(of: notificationBadges) { _, _ in
                        service.capsuleView?.needsDisplay = true
                    }

                Toggle(strings.notificationSoundToggle, isOn: $notificationSound)
                    .disabled(!notificationsEnabled)
            } header: {
                Text(strings.notificationSectionTitle)
            }

            Section {
                Toggle(strings.autoPauseToggle, isOn: $autoPause)
                    .onChange(of: autoPause) { _, isEnabled in
                        service.document.autoPauseMedia = isEnabled
                    }
                Text(strings.autoPauseCaption)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Toggle(strings.adBlockToggle, isOn: $adBlock)
                    .onChange(of: adBlock) { _, isEnabled in
                        service.document.enableAdBlock = isEnabled
                    }
                Text(strings.adBlockCaption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text(strings.experienceSectionTitle)
            }

            Section {
                ForEach(WebBarQuickAppPresets.catalog) { app in
                    quickAppRow(app)
                }
            } header: {
                Text(strings.quickAppsTitle)
            }
        }
        // Keep this page on the same native grouped Form system as Screenshot
        // settings: shared margins, rounded section surfaces and row dividers.
        .formStyle(.grouped)
    }

    private func quickAppRow(_ app: WebBarQuickApp) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(appColor(app).opacity(0.14))
                Image(systemName: app.iconSymbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(appColor(app))
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.body.weight(.medium))
                Text(app.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            Label(app.defaultViewport.rawValue, systemImage: app.defaultViewport.iconName)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.10), in: Capsule())
        }
        .padding(.vertical, 3)
    }

    private func appColor(_ app: WebBarQuickApp) -> Color {
        Color(nsColor: NSColor(hex: app.colorHex) ?? .controlAccentColor)
    }
}

private extension NSColor {
    convenience init?(hex: String) {
        var cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleanHex.hasPrefix("#") {
            cleanHex.removeFirst()
        }
        guard cleanHex.count == 6, let rgbValue = UInt64(cleanHex, radix: 16) else { return nil }
        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }
}
