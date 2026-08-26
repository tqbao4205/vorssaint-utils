// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import Foundation
import WebKit

struct WebBarScripts {
    static let pauseAllMedia: String = """
    (function() {
        try {
            var media = document.querySelectorAll('video, audio');
            for (var i = 0; i < media.length; i++) {
                media[i].pause();
            }
            var iframes = document.querySelectorAll('iframe');
            for (var j = 0; j < iframes.length; j++) {
                if (iframes[j].contentWindow) {
                    iframes[j].contentWindow.postMessage('{"event":"command","func":"pauseVideo","args":""}', '*');
                }
            }
        } catch (e) {}
    })();
    """

    static let extractFavicon: String = """
    (function() {
        var el = document.querySelector("link[rel*='icon'], link[rel='apple-touch-icon'], link[rel='shortcut icon']");
        return el ? el.href : (window.location.origin + '/favicon.ico');
    })();
    """

    static let googleOAuthSecurityShim: String = """
    (function() {
        try {
            if (!window.chrome) {
                window.chrome = { runtime: {}, app: {}, csi: function(){}, loadTimes: function(){} };
            }
            Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
        } catch(e) {}
    })();
    """

    static let zaloAutoActivateScript: String = """
    (function() {
        function autoClickActivate() {
            try {
                var elements = document.querySelectorAll('button, div[role="button"], a, .btn, .btn-primary, [class*="btn"], [class*="Button"], [data-translate-inner]');
                for (var i = 0; i < elements.length; i++) {
                    var el = elements[i];
                    var text = (el.innerText || el.textContent || '').trim().toLowerCase();
                    if (text === 'kích hoạt' || text === 'kich hoat' || text === 'activate' || (text.indexOf('kích hoạt') !== -1 && text.length < 25)) {
                        el.click();
                        return true;
                    }
                }
                var modals = document.querySelectorAll('.modal, .popup, [class*="modal"], [class*="popup"], [class*="dialog"], [class*="layer"]');
                for (var m = 0; m < modals.length; m++) {
                    var modalText = (modals[m].innerText || '').toLowerCase();
                    if (modalText.indexOf('tab khác') !== -1 || modalText.indexOf('kích hoạt') !== -1 || modalText.indexOf('another tab') !== -1) {
                        var btns = modals[m].querySelectorAll('button, div[role="button"], [class*="btn"], [class*="primary"]');
                        for (var b = 0; b < btns.length; b++) {
                            var bText = (btns[b].innerText || '').trim().toLowerCase();
                            if (bText.indexOf('kích hoạt') !== -1 || bText.indexOf('activate') !== -1 || btns.length === 1) {
                                btns[b].click();
                                return true;
                            }
                        }
                    }
                }
            } catch(e) {}
            return false;
        }
        autoClickActivate();
        var attempts = 0;
        var interval = setInterval(function() {
            attempts++;
            if (autoClickActivate() || attempts > 25) {
                clearInterval(interval);
            }
        }, 300);
    })();
    """
}

final class WebBarWebKitCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    weak var service: WebBarService?
    var tabID: UUID
    private var progressObservation: NSKeyValueObservation?

    init(service: WebBarService?, tabID: UUID) {
        self.service = service
        self.tabID = tabID
        super.init()
    }

    deinit {
        progressObservation?.invalidate()
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "notificationHandler", let dict = message.body as? [String: Any] {
            let title = dict["title"] as? String ?? ""
            let body = dict["body"] as? String ?? ""
            let tab = service?.document.tabs.first(where: { $0.id == tabID })
            let tabTitle = tab?.title ?? "WebBar"

            WebBarNotificationManager.shared.sendWebNotification(
                title: title,
                body: body,
                tabTitle: tabTitle,
                tabId: tabID
            )

            DispatchQueue.main.async { [weak self] in
                guard let self = self, let service = self.service else { return }
                let current = service.document.tabs.first(where: { $0.id == self.tabID })?.unreadCount ?? 0
                service.setUnreadCount(for: self.tabID, count: current + 1)
            }
        } else if message.name == "badgeHandler", let dict = message.body as? [String: Any] {
            let count = dict["count"] as? Int ?? 0
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.service?.setUnreadCount(for: self.tabID, count: count)
            }
        }
    }

    func setupProgressObserver(for webView: WKWebView) {
        progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
            DispatchQueue.main.async {
                guard let self = self, let service = self.service else { return }
                if service.document.selectedTabID == self.tabID {
                    service.currentProgress = webView.estimatedProgress
                }
            }
        }
    }

    // MARK: - Navigation Policy & Deep-link Interception

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        let scheme = url.scheme?.lowercased() ?? ""
        let urlStr = url.absoluteString.lowercased()

        // 1. Intercept and block mobile redirects to App Store / custom scheme launchers.
        let appSchemes = ["zalo", "fb", "fbauth2", "fb-messenger", "messenger", "msgr"]
        if scheme == "itms-apps" || scheme == "itms-appss"
            || urlStr.contains("apps.apple.com") || appSchemes.contains(scheme) {
            decisionHandler(.cancel)
            return
        }

        // 2. Messenger's standalone login bounces through an embedded Facebook
        // flow that can end on an unavailable-content page. Use Facebook's own
        // messages route instead: it shares the existing Facebook login cookie
        // and still renders responsively inside an iPhone-sized WebBar.
        if navigationAction.targetFrame?.isMainFrame != false,
           let host = url.host?.lowercased(),
           host == "messenger.com" || host.hasSuffix(".messenger.com") {
            if let messagesURL = Self.facebookMessagesURL(from: url) {
                webView.load(URLRequest(url: messagesURL))
                decisionHandler(.cancel)
                return
            }
        }

        // 3. Open target="_blank" links in current webview
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    private static func facebookMessagesURL(from messengerURL: URL) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.facebook.com"
        if messengerURL.path.hasPrefix("/t/") {
            components.path = "/messages" + messengerURL.path
        } else {
            components.path = "/messages/"
        }
        return components.url
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        DispatchQueue.main.async {
            guard let service = self.service else { return }
            if service.document.selectedTabID == self.tabID {
                service.isLoading = true
                if let urlString = webView.url?.absoluteString, !urlString.isEmpty {
                    service.urlInputText = urlString
                }
            }
        }
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        DispatchQueue.main.async {
            guard let service = self.service else { return }
            if service.document.selectedTabID == self.tabID {
                service.canGoBack = webView.canGoBack
                service.canGoForward = webView.canGoForward
            }
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let title = webView.title ?? ""
        let urlString = webView.url?.absoluteString ?? ""

        DispatchQueue.main.async {
            guard let service = self.service else { return }
            if service.document.selectedTabID == self.tabID {
                service.isLoading = false
                service.canGoBack = webView.canGoBack
                service.canGoForward = webView.canGoForward
                if !urlString.isEmpty {
                    service.urlInputText = urlString
                }
            }

            webView.evaluateJavaScript(WebBarScripts.extractFavicon) { result, _ in
                let faviconUrl = result as? String
                service.updateTabMetadata(id: self.tabID, title: title.isEmpty ? nil : title, url: urlString.isEmpty ? nil : urlString, favicon: faviconUrl)
            }

            if urlString.contains("zalo.me") {
                webView.evaluateJavaScript(WebBarScripts.zaloAutoActivateScript, completionHandler: nil)
            }
        }
    }

    // MARK: - WKUIDelegate Popups & Google OAuth

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        let urlStr = navigationAction.request.url?.absoluteString.lowercased() ?? ""

        let isOAuthOrPopup = urlStr.contains("accounts.google.com") ||
                             urlStr.contains("appleid.apple.com") ||
                             urlStr.contains("auth0.com") ||
                             urlStr.contains("oauth") ||
                             urlStr.contains("signin") ||
                             urlStr.contains("login") ||
                             navigationAction.targetFrame == nil

        if isOAuthOrPopup {
            let popupConfig = configuration
            let securityShimScript = WKUserScript(
                source: WebBarScripts.googleOAuthSecurityShim,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false
            )
            popupConfig.userContentController.addUserScript(securityShimScript)

            let popupWebView = WKWebView(frame: NSRect(x: 0, y: 0, width: 520, height: 680), configuration: popupConfig)
            popupWebView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36"
            popupWebView.uiDelegate = self
            popupWebView.navigationDelegate = self

            let popupWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 520, height: 680),
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            popupWindow.title = "Đăng nhập tài khoản"
            popupWindow.isReleasedWhenClosed = false
            popupWindow.center()
            popupWindow.contentView = popupWebView
            popupWindow.level = .floating
            popupWindow.makeKeyAndOrderFront(nil)

            return popupWebView
        }

        return nil
    }

    func webViewDidClose(_ webView: WKWebView) {
        if let window = webView.window {
            window.close()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.service?.reload()
        }
    }
}
