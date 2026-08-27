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
        ZStack {
            VStack(spacing: 0) {
                topControlBar
                contentArea
            }

            if let percentage = service.zoomHUDPercentage {
                Text("\(percentage)%")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 14)
                    .frame(height: 34)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay {
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.22), radius: 8, y: 3)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                    .allowsHitTesting(false)
                    .zIndex(10)
            }
        }
        .animation(.easeOut(duration: 0.16), value: service.zoomHUDPercentage)
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

            // 1. Viewport Mode Switcher
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

            // 2. Pin on Top
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

            // 3. Close Panel
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

    // MARK: - Content Area

    @ViewBuilder
    private var contentArea: some View {
        Group {
            if let tab = service.activeTab {
                if tab.urlString.isEmpty {
                    WebBarAddLinkAndAppsView(tab: tab)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else {
                    WebBarWKWebViewContainer(tab: tab)
                        .id(tab.id)
                        .transition(.opacity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.32), value: service.document.selectedTabID)
    }
}

// MARK: - Add Website & Quick Apps View (Matching Image 2)

// MARK: - Add Website View (Single Link Input Mode)

enum WebBarURLValidationState: Equatable {
    case idle
    case valid
    case invalid(String)
}

struct WebBarAddLinkAndAppsView: View {
    let tab: WebBarTab

    @ObservedObject private var service = WebBarService.shared
    @ObservedObject private var l10n = L10n.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchInput: String = ""
    @FocusState private var isFieldFocused: Bool
    @State private var validationState: WebBarURLValidationState = .idle
    @State private var isOpening: Bool = false
    @State private var pendingErrorDismissal: DispatchWorkItem?

    private var strings: WebBarFeatureStrings { FeatureStrings.webBar(l10n.language) }

    private var invalidURLErrorText: String {
        switch l10n.language {
        case .vi:
            return "Liên kết không hợp lệ"
        case .ja:
            return "無効なURLです"
        case .zhHans, .zhTW, .zhHK:
            return "网址无效"
        default:
            return "Invalid URL"
        }
    }

    private var emptyURLErrorText: String {
        switch l10n.language {
        case .vi:
            return "Vui lòng nhập liên kết"
        default:
            return "URL required"
        }
    }

    private var emptyClipboardErrorText: String {
        switch l10n.language {
        case .vi:
            return "Bộ nhớ tạm trống"
        default:
            return "Clipboard is empty"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                inputSection

                if case .invalid(let message) = validationState {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 11.5))
                        Text(message)
                            .font(.system(size: 11.5, weight: .medium))
                            .lineLimit(2)
                        Spacer()
                    }
                    .foregroundStyle(Color.red)
                    .padding(.horizontal, 4)
                    .padding(.top, 6)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, 16)

            Spacer(minLength: 4)

            footerSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.2), value: validationState)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isFieldFocused = true
            }
        }
        .onDisappear {
            pendingErrorDismissal?.cancel()
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

    // MARK: - Input Box Section
    private var borderColor: Color {
        switch validationState {
        case .valid:
            return Color.green
        case .invalid:
            return Color.red
        case .idle:
            return isFieldFocused ? Color.accentColor : Color.white.opacity(0.12)
        }
    }

    private var iconColor: Color {
        switch validationState {
        case .valid:
            return Color.green
        case .invalid:
            return Color.red
        case .idle:
            return isFieldFocused ? Color.accentColor : .secondary
        }
    }

    private var inputSection: some View {
        HStack(spacing: 10) {
            Image(systemName: validationState == .valid ? "checkmark.circle.fill" : "globe")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(iconColor)
                .scaleEffect(validationState == .valid ? 1.15 : 1.0)
                .animation(.spring(response: 0.32, dampingFraction: 0.65), value: validationState)

            TextField(strings.searchPlaceholder, text: $searchInput)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($isFieldFocused)
                .onSubmit {
                    submitInput()
                }
                .onChange(of: searchInput) { _, _ in
                    if case .invalid = validationState {
                        pendingErrorDismissal?.cancel()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            validationState = .idle
                        }
                    }
                }

            trailingButton
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(
            ZStack {
                PanelSurface.controlFill(for: colorScheme)
                if validationState == .valid {
                    Color.green.opacity(0.08)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(borderColor, lineWidth: (isFieldFocused || validationState != .idle) ? 1.5 : 1)
        )
        .animation(.easeInOut(duration: 0.25), value: validationState)
    }

    @ViewBuilder
    private var trailingButton: some View {
        if !searchInput.isEmpty {
            Button {
                submitInput()
            } label: {
                HStack(spacing: 4) {
                    if isOpening {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 14, height: 14)
                    } else {
                        Text(strings.openButton)
                            .font(.system(size: 12, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(validationState == .valid ? Color.green : Color.accentColor)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isOpening)
            .animation(.easeInOut(duration: 0.2), value: validationState)
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
            .disabled(isOpening)
        }
    }

    private func showError(_ message: String) {
        pendingErrorDismissal?.cancel()
        withAnimation(.easeInOut(duration: 0.2)) {
            validationState = .invalid(message)
        }
        let work = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.25)) {
                if case .invalid = validationState {
                    validationState = .idle
                }
            }
        }
        pendingErrorDismissal = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: work)
    }

    private func pasteAndSubmit() {
        guard !isOpening else { return }
        if let clip = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !clip.isEmpty {
            searchInput = clip
            submitInput()
        } else {
            showError(emptyClipboardErrorText)
        }
    }

    private func submitInput() {
        guard !isOpening else { return }
        let text = searchInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            showError(emptyURLErrorText)
            return
        }

        if let validURL = WebBarService.validateAndNormalizeURL(text) {
            pendingErrorDismissal?.cancel()
            withAnimation(.spring(response: 0.32, dampingFraction: 0.7)) {
                validationState = .valid
            }
            isOpening = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                withAnimation(.easeInOut(duration: 0.32)) {
                    service.openWebsite(rawInput: validURL, forTabID: tab.id)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    searchInput = ""
                    validationState = .idle
                    isOpening = false
                }
            }
        } else {
            showError(invalidURLErrorText)
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
        WebBarUserAgentPolicy.userAgent(for: tab.urlString, viewport: tab.viewport)
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
