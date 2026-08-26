// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import Carbon.HIToolbox
import Combine
import SwiftUI
import WebKit

final class WebBarService: NSObject, ObservableObject, NSWindowDelegate {
    static let shared = WebBarService()

    @Published private(set) var shortcutRegistrationFailed = false
    @Published var document: WebBarDocument = .defaultDocument {
        didSet {
            scheduleSave()
            capsuleView?.updateCapsuleLayout()
        }
    }
    @Published var urlInputText: String = ""
    @Published var isLoading: Bool = false
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var currentProgress: Double = 0.0

    // Status Bar Capsule
    private(set) var capsuleStatusItem: NSStatusItem?
    private(set) var capsuleView: WebBarCapsuleNSView?

    private let hotkey = QuickToolHotkey(id: 19)
    private var panel: NSPanel?
    private var keyMonitor: Any?
    private var localClickMonitor: Any?
    private var outsideClickMonitor: Any?
    private var pendingSave: DispatchWorkItem?
    private var webViews: [UUID: WKWebView] = [:]
    private var hasLoaded = false

    private override init() {
        super.init()
        hotkey.onPress = { [weak self] in self?.toggle() }
        loadDocument()
        syncStatusItems()
        WebBarNotificationManager.shared.requestAuthorization()
        WebBarNotificationManager.shared.onNotificationClicked = { [weak self] tabId in
            guard let self = self else { return }
            if let tabId = tabId {
                self.selectTab(id: tabId)
                self.show(for: tabId)
            } else {
                self.show()
            }
        }
    }

    func syncWithPreferences() {
        let available = AppFeature.webBar.isAvailable
        let enabled = available
            && UserDefaults.standard.bool(forKey: DefaultsKey.webBarShortcutEnabled)
        let shortcut = GlobalShortcut.saved(for: DefaultsKey.webBarShortcut,
                                            fallback: .webBarDefault)
        shortcutRegistrationFailed = !hotkey.sync(enabled: enabled, shortcut: shortcut)

        let showOnMenuBar = available && UserDefaults.standard.bool(forKey: DefaultsKey.webBarShowOnMenuBar)
        if showOnMenuBar {
            syncStatusItems()
        } else {
            removeStatusItem()
        }

        if !available {
            hide()
            panel = nil
        }
    }

    func suspend() {
        hotkey.unregister()
        hide()
        removeStatusItem()
    }

    var isVisible: Bool {
        panel?.isVisible == true
    }

    var activeTab: WebBarTab? {
        document.tabs.first(where: { $0.id == document.selectedTabID }) ?? document.tabs.first
    }

    // MARK: - Menu Bar Status Item Management

    func syncStatusItems() {
        guard AppFeature.webBar.isAvailable,
              UserDefaults.standard.bool(forKey: DefaultsKey.webBarShowOnMenuBar) else {
            removeStatusItem()
            return
        }

        if capsuleStatusItem == nil {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            self.capsuleStatusItem = item

            let capsule = WebBarCapsuleNSView(service: self)
            self.capsuleView = capsule

            if let button = item.button {
                button.target = nil
                button.action = nil
                button.subviews.forEach { $0.removeFromSuperview() }
                button.addSubview(capsule)

                capsule.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    capsule.leadingAnchor.constraint(equalTo: button.leadingAnchor),
                    capsule.trailingAnchor.constraint(equalTo: button.trailingAnchor),
                    capsule.topAnchor.constraint(equalTo: button.topAnchor),
                    capsule.bottomAnchor.constraint(equalTo: button.bottomAnchor)
                ])
            }
        }

        capsuleView?.updateCapsuleLayout()
    }

    func setCapsuleStatusItemLength(_ length: CGFloat) {
        capsuleStatusItem?.length = length
    }

    private func removeStatusItem() {
        if let item = capsuleStatusItem {
            NSStatusBar.system.removeStatusItem(item)
            capsuleStatusItem = nil
            capsuleView = nil
        }
    }

    // MARK: - Panel Toggle & Visibility

    func toggle() {
        if isVisible, panel?.isKeyWindow == true {
            hide()
        } else {
            show()
        }
    }

    func show(for tabId: UUID? = nil) {
        guard AppFeature.webBar.isAvailable else { return }

        if let tabId = tabId {
            document.selectedTabID = tabId
            if let tab = activeTab {
                urlInputText = tab.urlString
            }
        }

        let panel = ensurePanel()
        installMonitors(for: panel)

        positionPanelUnderStatusBar(for: tabId ?? document.selectedTabID, animated: false)

        panel.alphaValue = 0
        panel.orderFrontRegardless()
        panel.makeKey()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            panel.animator().alphaValue = CGFloat(document.windowOpacity)
        }

        capsuleView?.needsDisplay = true
    }

    func hide() {
        guard panel != nil else { return }
        if document.autoPauseMedia {
            pauseAllMedia()
        }
        rememberCustomSizeIfNeeded()
        flushSave()
        removeMonitors()
        panel?.orderOut(nil)
        capsuleView?.needsDisplay = true
    }

    // MARK: - Tab & Navigation Management

    func selectTab(id: UUID) {
        rememberCustomSizeIfNeeded()

        // Clean up unused blank tabs if switching away to another tab
        if let current = activeTab, current.urlString.isEmpty, current.id != id, document.tabs.count > 1 {
            if let idx = document.tabs.firstIndex(where: { $0.id == current.id }) {
                document.tabs.remove(at: idx)
            }
        }

        guard let target = document.tabs.first(where: { $0.id == id }) else { return }
        document.selectedTabID = id
        if let idx = document.tabs.firstIndex(where: { $0.id == id }) {
            document.tabs[idx].unreadCount = 0
        }
        urlInputText = target.urlString
        positionPanelUnderStatusBar(for: id, animated: true)
        flushSave()
        capsuleView?.updateCapsuleLayout()
    }

    func addNewTab(url: String = "", viewport: WebBarViewportMode = .iphoneSE) {
        rememberCustomSizeIfNeeded()

        // Clean up any extra unused blank tabs
        if url.isEmpty {
            let blankTabs = document.tabs.filter { $0.urlString.isEmpty }
            if let firstBlank = blankTabs.first {
                selectTab(id: firstBlank.id)
                return
            }
        }

        let newTab = WebBarTab(
            title: url.isEmpty ? "New Tab" : url,
            urlString: url,
            viewport: viewport
        )
        document.tabs.append(newTab)
        document.selectedTabID = newTab.id
        urlInputText = url
        positionPanelUnderStatusBar(for: newTab.id, animated: true)
        flushSave()
        capsuleView?.updateCapsuleLayout()
    }

    func openWebsite(rawInput: String, viewport: WebBarViewportMode = .iphoneSE, forTabID: UUID? = nil) {
        let trimmed = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        rememberCustomSizeIfNeeded()

        let targetURL: String
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            targetURL = trimmed
        } else if trimmed.contains(".") && !trimmed.contains(" ") {
            targetURL = "https://" + trimmed
        } else {
            let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
            targetURL = "https://www.google.com/search?q=" + encoded
        }

        // 1. If explicit forTabID is provided and is blank:
        if let targetID = forTabID,
           let idx = document.tabs.firstIndex(where: { $0.id == targetID }),
           document.tabs[idx].urlString.isEmpty {
            document.tabs[idx].urlString = targetURL
            document.tabs[idx].viewport = viewport
            document.selectedTabID = targetID
            urlInputText = targetURL
            positionPanelUnderStatusBar(for: targetID, animated: true)
            if let url = URL(string: targetURL) {
                webViews[targetID]?.load(URLRequest(url: url))
            }
        } else if let active = activeTab, active.urlString.isEmpty {
            // 2. If current active tab is blank, fill it:
            if let idx = document.tabs.firstIndex(where: { $0.id == active.id }) {
                document.tabs[idx].urlString = targetURL
                document.tabs[idx].viewport = viewport
                urlInputText = targetURL
                positionPanelUnderStatusBar(for: active.id, animated: true)
                if let url = URL(string: targetURL) {
                    webViews[active.id]?.load(URLRequest(url: url))
                }
            }
        } else {
            // 3. Current tab is already loaded with a website -> Create a BRAND NEW tab!
            let newTab = WebBarTab(
                title: targetURL,
                urlString: targetURL,
                viewport: viewport
            )
            document.tabs.append(newTab)
            document.selectedTabID = newTab.id
            urlInputText = targetURL
            positionPanelUnderStatusBar(for: newTab.id, animated: true)
        }

        flushSave()
        capsuleView?.updateCapsuleLayout()
    }

    func closeTab(id: UUID) {
        rememberCustomSizeIfNeeded()

        webViews[id]?.stopLoading()
        webViews.removeValue(forKey: id)

        guard document.tabs.count > 1 else {
            if let idx = document.tabs.firstIndex(where: { $0.id == id }) {
                document.tabs[idx].urlString = ""
                document.tabs[idx].title = "New Tab"
                urlInputText = ""
            }
            flushSave()
            capsuleView?.updateCapsuleLayout()
            return
        }

        if let idx = document.tabs.firstIndex(where: { $0.id == id }) {
            document.tabs.remove(at: idx)
            if document.selectedTabID == id {
                let nextIdx = min(idx, document.tabs.count - 1)
                document.selectedTabID = document.tabs[nextIdx].id
                urlInputText = document.tabs[nextIdx].urlString
                positionPanelUnderStatusBar(for: document.tabs[nextIdx].id, animated: true)
            }
        }
        flushSave()
        capsuleView?.updateCapsuleLayout()
    }

    func setViewport(_ mode: WebBarViewportMode) {
        rememberCustomSizeIfNeeded()

        guard let activeID = activeTab?.id,
              let idx = document.tabs.firstIndex(where: { $0.id == activeID }) else { return }
        document.tabs[idx].viewport = mode
        positionPanelUnderStatusBar(for: activeID, animated: true)

        if let webView = webViews[activeID] {
            let tab = document.tabs[idx]
            let newUA = WebBarUserAgentPolicy.userAgent(for: tab.urlString, viewport: mode)

            if webView.customUserAgent != newUA {
                webView.customUserAgent = newUA
                webView.reload()
            }
        }
        flushSave()
    }

    func reload() {
        if let activeID = activeTab?.id {
            webViews[activeID]?.reload()
        }
    }

    func goBack() {
        if let activeID = activeTab?.id, webViews[activeID]?.canGoBack == true {
            webViews[activeID]?.goBack()
        }
    }

    func goForward() {
        if let activeID = activeTab?.id, webViews[activeID]?.canGoForward == true {
            webViews[activeID]?.goForward()
        }
    }

    func zoomIn() {
        guard let activeID = activeTab?.id,
              let idx = document.tabs.firstIndex(where: { $0.id == activeID }) else { return }
        let newZoom = min(document.tabs[idx].zoomLevel + 0.1, 2.5)
        document.tabs[idx].zoomLevel = newZoom
        webViews[activeID]?.pageZoom = CGFloat(newZoom)
        flushSave()
    }

    func zoomOut() {
        guard let activeID = activeTab?.id,
              let idx = document.tabs.firstIndex(where: { $0.id == activeID }) else { return }
        let newZoom = max(document.tabs[idx].zoomLevel - 0.1, 0.5)
        document.tabs[idx].zoomLevel = newZoom
        webViews[activeID]?.pageZoom = CGFloat(newZoom)
        flushSave()
    }

    func zoomReset() {
        guard let activeID = activeTab?.id,
              let idx = document.tabs.firstIndex(where: { $0.id == activeID }) else { return }
        document.tabs[idx].zoomLevel = 1.0
        webViews[activeID]?.pageZoom = 1.0
        flushSave()
    }

    func togglePin() {
        document.isPinned.toggle()
        if let panel {
            panel.level = document.isPinned ? .floating : .normal
        }
        flushSave()
    }

    func setWindowOpacity(_ opacity: Double) {
        document.windowOpacity = opacity
        if let panel {
            panel.alphaValue = CGFloat(opacity)
        }
        flushSave()
    }

    func registerWebView(_ webView: WKWebView, for tabID: UUID) {
        webViews[tabID] = webView
    }

    func getWebView(for tabID: UUID) -> WKWebView? {
        webViews[tabID]
    }

    func setUnreadCount(for tabID: UUID, count: Int) {
        guard let idx = document.tabs.firstIndex(where: { $0.id == tabID }) else { return }
        if document.selectedTabID == tabID && isVisible {
            if document.tabs[idx].unreadCount != 0 {
                document.tabs[idx].unreadCount = 0
                capsuleView?.needsDisplay = true
            }
            return
        }
        let newCount = max(0, count)
        if document.tabs[idx].unreadCount != newCount {
            document.tabs[idx].unreadCount = newCount
            capsuleView?.needsDisplay = true
        }
    }

    func updateTabMetadata(id: UUID, title: String?, url: String?, favicon: String?) {
        guard let idx = document.tabs.firstIndex(where: { $0.id == id }) else { return }
        if let title = title, !title.isEmpty {
            document.tabs[idx].title = title
        }
        if let url = url, !url.isEmpty {
            document.tabs[idx].urlString = url
        }
        if let favicon = favicon, !favicon.isEmpty {
            document.tabs[idx].faviconUrl = favicon
        }
        flushSave()
        capsuleView?.updateCapsuleLayout()
    }

    func pauseAllMedia() {
        for (_, webView) in webViews {
            webView.evaluateJavaScript(WebBarScripts.pauseAllMedia, completionHandler: nil)
        }
    }

    // MARK: - Objective-C Context Menu Selectors

    @objc func menuActionReload() {
        reload()
    }

    @objc func menuActionCloseActiveTab() {
        if let id = activeTab?.id {
            closeTab(id: id)
        }
    }

    @objc func menuActionNewTab() {
        addNewTab()
        show()
    }

    @objc func menuActionOpenQuickApps() {
        addNewTab()
        show()
    }

    @objc func menuActionOpenSettings() {
        SettingsRouter.shared.page = .webBar
        appDelegate()?.openSettingsWindow()
    }

    // MARK: - Panel & Window Management

    private final class KeyableWebBarPanel: NSPanel {
        override var canBecomeKey: Bool { true }
        override var canBecomeMain: Bool { true }
    }

    private func ensurePanel() -> NSPanel {
        if let panel { return panel }
        let targetTab = document.tabs.first(where: { $0.id == document.selectedTabID }) ?? activeTab
        let viewport = targetTab?.viewport ?? .iphoneSE
        let startSize = viewport == .custom
            ? CGSize(width: document.customWidth, height: document.customHeight)
            : viewport.size

        let panel = KeyableWebBarPanel(contentRect: NSRect(origin: .zero, size: startSize),
                                       styleMask: [.borderless, .nonactivatingPanel, .resizable],
                                       backing: .buffered,
                                       defer: false)
        panel.title = "WebBar"
        panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false
        panel.level = document.isPinned ? .floating : .normal
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.contentMinSize = NSSize(width: 320, height: 400)

        let host = NSHostingController(rootView: WebBarView())
        host.sizingOptions = []
        panel.contentViewController = host
        panel.setContentSize(startSize)
        panel.delegate = self
        self.panel = panel
        return panel
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        guard let resizedPanel = notification.object as? NSPanel,
              resizedPanel === panel else { return }
        rememberCustomSizeIfNeeded(from: resizedPanel)
        flushSave()
    }

    /// The Custom viewport is a reusable display preset. Remember its final
    /// content size before another tab or preset resizes the shared panel.
    private func rememberCustomSizeIfNeeded(from candidate: NSPanel? = nil) {
        guard activeTab?.viewport == .custom,
              let currentPanel = candidate ?? panel else { return }

        let size = currentPanel.contentLayoutRect.size
        let width = Double(size.width.rounded())
        let height = Double(size.height.rounded())
        guard width >= 320, height >= 400,
              abs(document.customWidth - width) >= 0.5
                || abs(document.customHeight - height) >= 0.5 else { return }

        var updatedDocument = document
        updatedDocument.customWidth = width
        updatedDocument.customHeight = height
        document = updatedDocument
    }

    func positionPanelUnderStatusBar(for tabId: UUID? = nil, animated: Bool = false) {
        guard let panel = panel else { return }

        let targetTab = document.tabs.first(where: { $0.id == (tabId ?? document.selectedTabID) }) ?? activeTab
        let viewport = targetTab?.viewport ?? .iphoneSE
        let panelSize = viewport == .custom
            ? CGSize(width: document.customWidth, height: document.customHeight)
            : viewport.size

        guard let item = capsuleStatusItem,
              let button = item.button,
              let buttonWindow = button.window else {
            if !NSScreen.screens.contains(where: { $0.visibleFrame.intersects(panel.frame) }) {
                center(panel, size: panelSize)
            } else {
                var f = panel.frame
                f.size = panelSize
                panel.setFrame(f, display: true)
            }
            return
        }

        let screen = buttonWindow.screen
            ?? NSScreen.screens.first(where: { NSMouseInRect(buttonWindow.frame.origin, $0.frame, false) })
            ?? NSScreen.main
            ?? NSScreen.screens[0]

        let screenVisibleFrame = screen.visibleFrame

        let relativeX = capsuleView?.tabCenterRelativeX(for: tabId ?? document.selectedTabID) ?? (buttonWindow.frame.width / 2.0)
        let tabScreenX: CGFloat
        if let capsule = capsuleView, let win = capsule.window {
            let localPoint = NSPoint(x: relativeX, y: capsule.bounds.midY)
            let windowPoint = capsule.convert(localPoint, to: nil)
            let screenPoint = win.convertToScreen(NSRect(origin: windowPoint, size: .zero)).origin
            tabScreenX = screenPoint.x
        } else {
            tabScreenX = buttonWindow.frame.origin.x + relativeX
        }

        var x = tabScreenX - (panelSize.width / 2.0)
        x = max(screenVisibleFrame.minX + 8, min(x, screenVisibleFrame.maxX - panelSize.width - 8))

        let y = buttonWindow.frame.minY - panelSize.height - 10
        let targetFrame = NSRect(x: x, y: y, width: panelSize.width, height: panelSize.height)

        if animated && panel.isVisible {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.26
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
                panel.animator().setFrame(targetFrame, display: true)
            }
        } else {
            panel.setFrame(targetFrame, display: true)
        }
    }

    private func center(_ panel: NSPanel, size: CGSize) {
        let screen = NSScreen.pointerVisibleFrame
        let x = screen.midX - size.width / 2
        let y = screen.minY + (screen.height - size.height) * 0.55
        panel.setFrame(NSRect(x: max(screen.minX + 16, min(x, screen.maxX - size.width - 16)),
                              y: max(screen.minY + 16, min(y, screen.maxY - size.height - 16)),
                              width: size.width,
                              height: size.height),
                       display: true,
                       animate: false)
    }

    private func installMonitors(for panel: NSPanel) {
        removeMonitors()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self, weak panel] event in
            guard let self, let panel, event.window === panel else { return event }

            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if let command = WebBarZoomShortcut.command(
                forKeyCode: event.keyCode,
                hasCommand: flags.contains(.command),
                hasControl: flags.contains(.control),
                hasOption: flags.contains(.option)
            ) {
                switch command {
                case .zoomIn: self.zoomIn()
                case .zoomOut: self.zoomOut()
                case .reset: self.zoomReset()
                }
                return nil
            }

            if event.keyCode == 53 { // Esc
                if let active = self.activeTab, active.urlString.isEmpty, self.document.tabs.count > 1 {
                    self.closeTab(id: active.id)
                    return nil
                }
                if UserDefaults.standard.bool(forKey: DefaultsKey.webBarCloseOnClickOutside) {
                    self.hide()
                    return nil
                }
            }
            return event
        }

        let mouseEvents: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: mouseEvents) { [weak self, weak panel] event in
            guard let self, let panel, panel.isVisible, !self.document.isPinned else { return event }
            if event.window !== panel, !Self.mouseIsInside(panel) {
                self.hide()
            }
            return event
        }
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: mouseEvents) { [weak self, weak panel] event in
            guard let self, let panel, panel.isVisible, !self.document.isPinned else { return }
            if event.windowNumber != panel.windowNumber, !Self.mouseIsInside(panel) {
                self.hide()
            }
        }
    }

    /// Treat the resize edge as part of WebBar so grabbing it never dismisses
    /// the panel before AppKit can begin the resize operation.
    private static func mouseIsInside(_ panel: NSPanel) -> Bool {
        panel.frame.insetBy(dx: -2, dy: -2).contains(NSEvent.mouseLocation)
    }

    private func removeMonitors() {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil
        if let localClickMonitor { NSEvent.removeMonitor(localClickMonitor) }
        localClickMonitor = nil
        if let outsideClickMonitor { NSEvent.removeMonitor(outsideClickMonitor) }
        outsideClickMonitor = nil
    }

    // MARK: - Persistence

    private func loadDocument() {
        hasLoaded = true
        if let data = UserDefaults.standard.data(forKey: DefaultsKey.webBarDocument),
           let decoded = try? JSONDecoder().decode(WebBarDocument.self, from: data),
           !decoded.tabs.isEmpty {
            self.document = decoded
            if let tab = decoded.tabs.first(where: { $0.id == decoded.selectedTabID }) ?? decoded.tabs.first {
                self.urlInputText = tab.urlString
            }
        }
    }

    private func scheduleSave() {
        pendingSave?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.flushSave() }
        pendingSave = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }

    private func flushSave() {
        pendingSave?.cancel()
        if let encoded = try? JSONEncoder().encode(document) {
            UserDefaults.standard.set(encoded, forKey: DefaultsKey.webBarDocument)
        }
    }
}
