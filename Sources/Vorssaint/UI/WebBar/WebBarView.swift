// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import SwiftUI
import WebKit

struct WebBarView: View {
    @ObservedObject private var service = WebBarService.shared
    @ObservedObject private var l10n = L10n.shared
    @Environment(\.colorScheme) private var colorScheme

    private var strings: WebBarFeatureStrings { FeatureStrings.webBar(l10n.language) }

    var body: some View {
        VStack(spacing: 0) {
            topControlBar
            contentArea
        }
        .background {
            ZStack {
                HUDBackdrop(cornerRadius: 14)
                Color(nsColor: .windowBackgroundColor)
                    .opacity(service.document.windowOpacity < 1.0 ? 0.3 : 0.95)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: - Top Control Bar (Only Right Functional Buttons)

    private var topControlBar: some View {
        HStack(spacing: 6) {
            if let activeTab = service.activeTab, !activeTab.urlString.isEmpty {
                Text(activeTab.title.isEmpty ? activeTab.urlString : activeTab.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.leading, 6)
            }

            Spacer()

            // 1. Add New Tab / Link
            Button {
                service.addNewTab()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 22)
                    .background(PanelSurface.controlFill(for: colorScheme))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help(strings.newTab)

            // 2. Quick Apps Toggle
            Button {
                service.addNewTab()
            } label: {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 22)
            }
            .buttonStyle(.plain)
            .help(strings.quickAppsTitle)

            // 3. Viewport Mode Switcher
            Menu {
                ForEach(WebBarViewportMode.allCases) { mode in
                    Button {
                        service.setViewport(mode)
                    } label: {
                        HStack {
                            Text(mode.rawValue)
                            if service.activeTab?.viewport == mode {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: service.activeTab?.viewport.iconName ?? "iphone")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 22)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .menuIndicator(.hidden)
            .frame(width: 24)
            .help(strings.viewportLabel)

            // 4. Pin on Top
            Button {
                service.togglePin()
            } label: {
                Image(systemName: service.document.isPinned ? "pin.fill" : "pin")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(service.document.isPinned ? Color.accentColor : .secondary)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .help(service.document.isPinned ? strings.unpinLabel : strings.pinLabel)

            // 5. Close Panel
            Button {
                service.hide()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
                    .background(PanelSurface.controlFill(for: colorScheme))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    // MARK: - Content Area (Isolated Multi-Tab ZStack)

    @ViewBuilder
    private var contentArea: some View {
        ZStack {
            ForEach(service.document.tabs) { tab in
                let isSelected = (tab.id == service.document.selectedTabID)
                ZStack {
                    if tab.urlString.isEmpty {
                        WebBarAddLinkAndAppsView(tab: tab)
                    } else {
                        WebBarWKWebViewContainer(tab: tab)
                            .id(tab.id)
                    }
                }
                .opacity(isSelected ? 1.0 : 0.0)
                .allowsHitTesting(isSelected)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Add Website & Quick Apps View (Matching Image 2)

struct WebBarAddLinkAndAppsView: View {
    let tab: WebBarTab

    @ObservedObject private var service = WebBarService.shared
    @ObservedObject private var l10n = L10n.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchInput: String = ""
    @FocusState private var isFieldFocused: Bool

    private var strings: WebBarFeatureStrings { FeatureStrings.webBar(l10n.language) }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 12)

            inputSection
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            quickAppsGrid
                .padding(.horizontal, 16)

            Spacer(minLength: 4)

            footerSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isFieldFocused = true
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.18))
                    .frame(width: 28, height: 28)

                Image(systemName: "link")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.accentColor)
            }

            Text(strings.pasteLinkTitle)
                .font(.system(size: 13.5, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Spacer()

            if service.document.tabs.count > 1 {
                Button {
                    service.closeTab(id: tab.id)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Input Box Section (Matching Image 2)
    private var inputSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "globe")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(isFieldFocused ? Color.accentColor : .secondary)

            TextField(strings.searchPlaceholder, text: $searchInput)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($isFieldFocused)
                .onSubmit {
                    submitInput()
                }

            trailingButton
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(PanelSurface.controlFill(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(isFieldFocused ? Color.accentColor : Color.white.opacity(0.12), lineWidth: isFieldFocused ? 1.5 : 1)
        )
    }

    @ViewBuilder
    private var trailingButton: some View {
        if !searchInput.isEmpty {
            Button {
                submitInput()
            } label: {
                HStack(spacing: 4) {
                    Text(strings.openButton)
                        .font(.system(size: 12, weight: .bold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentColor)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        } else {
            Button {
                pasteAndSubmit()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 11))
                    Text(strings.pasteLinkButton)
                        .font(.system(size: 11.5, weight: .medium))
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private func pasteAndSubmit() {
        if let clip = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !clip.isEmpty {
            searchInput = clip
            submitInput()
        }
    }

    private func submitInput() {
        let text = searchInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        service.openWebsite(rawInput: text, forTabID: tab.id)
        searchInput = ""
    }

    // MARK: - Quick Apps Grid Section
    private var quickAppsGrid: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                appCategorySection(
                    title: strings.quickAppsCategoryAI,
                    apps: WebBarQuickAppPresets.catalog.filter { $0.category == .ai }
                )
                appCategorySection(
                    title: strings.quickAppsCategoryTools,
                    apps: WebBarQuickAppPresets.catalog.filter { $0.category == .tools }
                )
                appCategorySection(
                    title: strings.quickAppsCategorySocial,
                    apps: WebBarQuickAppPresets.catalog.filter { $0.category == .social }
                )
            }
            .padding(.vertical, 4)
        }
    }

    private func appCategorySection(title: String, apps: [WebBarQuickApp]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80, maximum: 110), spacing: 8)], spacing: 8) {
                ForEach(apps) { app in
                    Button {
                        service.openWebsite(rawInput: app.urlString, viewport: app.defaultViewport, forTabID: tab.id)
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: app.iconSymbol)
                                .font(.system(size: 18))
                                .foregroundStyle(Color(hex: app.colorHex))
                                .frame(width: 34, height: 34)
                                .background(Color(hex: app.colorHex).opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                            Text(app.name)
                                .font(.system(size: 10, weight: .medium))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(PanelSurface.cardFill(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Footer
    private var footerSection: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.12)

            HStack(spacing: 12) {
                Text(l10n.language == .vi ? "↵ Enter Mở" : "↵ Enter Open")
                Text("•")
                Text(l10n.language == .vi ? "⌘V Dán" : "⌘V Paste")
                Text("•")
                Text(l10n.language == .vi ? "Esc Hủy" : "Esc Cancel")
            }
            .font(.system(size: 9.5, weight: .medium))
            .foregroundStyle(.secondary.opacity(0.65))
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.18))
        }
    }
}

// MARK: - WKWebView Representable

struct WebBarWKWebViewContainer: NSViewRepresentable {
    let tab: WebBarTab

    func makeCoordinator() -> WebBarWebKitCoordinator {
        WebBarWebKitCoordinator(service: WebBarService.shared, tabID: tab.id)
    }

    private func effectiveUserAgent(for tab: WebBarTab) -> String {
        let lower = tab.urlString.lowercased()
        // 1. Zalo, Messenger, Facebook, TikTok: Always use desktop Safari Mac user agent so full web chat is served without app download prompts
        if lower.contains("zalo.me") || lower.contains("messenger.com") || lower.contains("facebook.com") || lower.contains("fb.com") || lower.contains("tiktok.com") {
            return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15"
        }
        // 2. Google OAuth, ChatGPT, OpenAI, Claude: Always use desktop Chrome Mac user agent to prevent disallowed_useragent
        if lower.contains("accounts.google") || lower.contains("chatgpt.com") || lower.contains("openai.com") || lower.contains("claude.ai") || lower.contains("auth0") {
            return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36"
        }
        return tab.viewport.userAgent
    }

    func makeNSView(context: Context) -> WKWebView {
        if let existing = WebBarService.shared.getWebView(for: tab.id) {
            return existing
        }

        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()
        config.allowsAirPlayForMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.javaScriptCanOpenWindowsAutomatically = true

        let userContent = config.userContentController
        let oauthScript = WKUserScript(source: WebBarScripts.googleOAuthSecurityShim,
                                       injectionTime: .atDocumentStart,
                                       forMainFrameOnly: false)
        userContent.addUserScript(oauthScript)

        let notificationScript = WKUserScript(source: WebBarNotificationManager.shared.notificationBridgeScript,
                                              injectionTime: .atDocumentStart,
                                              forMainFrameOnly: false)
        userContent.addUserScript(notificationScript)
        userContent.add(context.coordinator, name: "notificationHandler")

        let badgeScript = WKUserScript(source: WebBarNotificationManager.shared.unreadBadgeDetectorScript,
                                       injectionTime: .atDocumentEnd,
                                       forMainFrameOnly: false)
        userContent.addUserScript(badgeScript)
        userContent.add(context.coordinator, name: "badgeHandler")

        if tab.urlString.contains("zalo.me") {
            let zaloScript = WKUserScript(source: WebBarScripts.zaloAutoActivateScript,
                                          injectionTime: .atDocumentEnd,
                                          forMainFrameOnly: false)
            userContent.addUserScript(zaloScript)
        }

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.customUserAgent = effectiveUserAgent(for: tab)
        webView.allowsBackForwardNavigationGestures = true
        webView.pageZoom = CGFloat(tab.zoomLevel)

        context.coordinator.setupProgressObserver(for: webView)
        WebBarService.shared.registerWebView(webView, for: tab.id)

        if let url = URL(string: tab.urlString), !tab.urlString.isEmpty {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        let expectedUA = effectiveUserAgent(for: tab)
        if nsView.customUserAgent != expectedUA {
            nsView.customUserAgent = expectedUA
        }
        if abs(Double(nsView.pageZoom) - tab.zoomLevel) > 0.01 {
            nsView.pageZoom = CGFloat(tab.zoomLevel)
        }
    }
}

// MARK: - Color Hex Helper

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
