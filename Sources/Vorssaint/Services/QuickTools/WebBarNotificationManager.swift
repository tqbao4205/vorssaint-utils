// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import Foundation
import UserNotifications

final class WebBarNotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = WebBarNotificationManager()

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    /// Script to bridge Web HTML5 Notification API to native macOS Notification Center
    var notificationBridgeScript: String {
        """
        (function() {
            function handleNotify(title, options) {
                options = options || {};
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.notificationHandler) {
                    window.webkit.messageHandlers.notificationHandler.postMessage({
                        title: String(title || ''),
                        body: String(options.body || ''),
                        icon: String(options.icon || ''),
                        tag: String(options.tag || '')
                    });
                }
            }

            try {
                var CustomNotification = function(title, options) {
                    handleNotify(title, options);
                    this.title = title;
                    this.onclick = null;
                    this.onclose = null;
                    this.close = function() {};
                };

                CustomNotification.permission = "granted";
                CustomNotification.requestPermission = function(callback) {
                    if (typeof callback === 'function') callback("granted");
                    return Promise.resolve("granted");
                };

                window.Notification = CustomNotification;

                if (window.ServiceWorkerRegistration) {
                    window.ServiceWorkerRegistration.prototype.showNotification = function(title, options) {
                        handleNotify(title, options);
                        return Promise.resolve();
                    };
                }
            } catch(e) {}
        })();
        """
    }

    /// Script to automatically detect unread message badges in real-time from Zalo, Messenger, Facebook, Telegram, WhatsApp and title tags
    var unreadBadgeDetectorScript: String {
        """
        (function() {
            var lastCount = -1;
            function scanBadges() {
                var count = 0;

                // 1. Zalo Web unread message badges
                var zaloBadges = document.querySelectorAll('.nav-tab__item--badge, .badge, [data-badge], .unread-red-dot, .chat-unread-count, .conv-item__badge, .zl-badge, .tab-item--badge');
                for (var i = 0; i < zaloBadges.length; i++) {
                    var el = zaloBadges[i];
                    if (el.offsetParent !== null) {
                        var txt = el.innerText.trim();
                        var n = parseInt(txt);
                        if (!isNaN(n) && n > 0) {
                            count += n;
                        } else {
                            count += 1;
                        }
                    }
                }

                // 2. Facebook / Messenger / Instagram unread indicators
                var metaBadges = document.querySelectorAll('[aria-label*="unread"], [aria-label*="chưa đọc"], [aria-label*="Unread"], span[role="status"]');
                for (var j = 0; j < metaBadges.length; j++) {
                    var mEl = metaBadges[j];
                    if (mEl.offsetParent !== null) {
                        var t = mEl.innerText.trim();
                        var num = parseInt(t);
                        if (!isNaN(num) && num > 0) count += num;
                        else count += 1;
                    }
                }

                // 3. Document Title Badge Fallback: "(2) Zalo", "(1) Facebook", "[3] Messenger"
                var titleMatch = document.title.match(/[\\(\\[\\{](\\d+|\\+[\\d]+)[\\)\\]\\}]/);
                if (titleMatch) {
                    var titleNum = parseInt(titleMatch[1]);
                    if (!isNaN(titleNum) && titleNum > 0) {
                        count = Math.max(count, titleNum);
                    } else {
                        count = Math.max(count, 1);
                    }
                }

                if (count !== lastCount) {
                    lastCount = count;
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.badgeHandler) {
                        window.webkit.messageHandlers.badgeHandler.postMessage({ count: count });
                    }
                }
            }

            try {
                var observer = new MutationObserver(scanBadges);
                if (document.head) {
                    observer.observe(document.head, { subtree: true, characterData: true, childList: true });
                }
                if (document.body) {
                    observer.observe(document.body, { subtree: true, childList: true, attributes: true });
                } else {
                    document.addEventListener('DOMContentLoaded', function() {
                        if (document.body) {
                            observer.observe(document.body, { subtree: true, childList: true, attributes: true });
                        }
                    });
                }
                setInterval(scanBadges, 2000);
                setTimeout(scanBadges, 1000);
            } catch(e) {}
        })();
        """
    }

    func sendWebNotification(title: String, body: String, tabTitle: String, tabId: UUID) {
        guard UserDefaults.standard.bool(forKey: DefaultsKey.webBarNotificationsEnabled) else { return }

        let content = UNMutableNotificationContent()
        content.title = tabTitle.isEmpty ? "WebBar" : tabTitle
        if !title.isEmpty {
            content.subtitle = title
        }
        content.body = body.isEmpty ? "Bạn có tin nhắn / thông báo mới" : body
        if UserDefaults.standard.bool(forKey: DefaultsKey.webBarNotificationSound) {
            content.sound = .default
        }
        content.userInfo = ["tabId": tabId.uuidString]

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    var onNotificationClicked: ((UUID?) -> Void)?

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let tabIdStr = userInfo["tabId"] as? String, let tabId = UUID(uuidString: tabIdStr) {
            DispatchQueue.main.async { [weak self] in
                self?.onNotificationClicked?(tabId)
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.onNotificationClicked?(nil)
            }
        }
        completionHandler()
    }
}
