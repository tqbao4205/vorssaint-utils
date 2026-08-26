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
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("WebBar")
                                .font(.system(size: 14, weight: .semibold))
                            Text(strings.panelCaption)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            service.show()
                        } label: {
                            Label(strings.openButton, systemImage: "globe")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding(.bottom, 4)

                    Toggle(strings.showOnMenuBar, isOn: $showOnMenuBar)
                        .onChange(of: showOnMenuBar) { _, _ in
                            service.syncWithPreferences()
                        }
                }
                .padding(.vertical, 4)
            } header: {
                Text(strings.pageTitle)
            }

            Section {
                Toggle(strings.notificationsToggle, isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { _, val in
                        if val {
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
                Text("Thông báo & Huy hiệu")
            }

            Section {
                Toggle(strings.autoPauseToggle, isOn: $autoPause)
                    .onChange(of: autoPause) { _, val in
                        service.document.autoPauseMedia = val
                    }
                Text(strings.autoPauseCaption)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Toggle(strings.adBlockToggle, isOn: $adBlock)
                    .onChange(of: adBlock) { _, val in
                        service.document.enableAdBlock = val
                    }
                Text(strings.adBlockCaption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Trải nghiệm & Bảo vệ")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(WebBarQuickAppPresets.catalog) { app in
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color(nsColor: NSColor(hex: app.colorHex) ?? .controlAccentColor).opacity(0.15))
                                    .frame(width: 28, height: 28)
                                Image(systemName: app.iconSymbol)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color(nsColor: NSColor(hex: app.colorHex) ?? .controlAccentColor))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(app.name)
                                    .font(.system(size: 12, weight: .medium))
                                Text(app.description)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(app.defaultViewport.rawValue)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.secondary.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .padding(.vertical, 3)
                    }
                }
            } header: {
                Text(strings.quickAppsTitle)
            }
        }
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
