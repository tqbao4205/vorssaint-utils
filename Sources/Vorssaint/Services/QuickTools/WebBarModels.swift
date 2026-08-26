// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import CoreGraphics
import Foundation

enum WebBarViewportMode: String, Codable, CaseIterable, Identifiable {
    case iphoneSE = "iPhone SE"
    case iphonePro = "iPhone 16 Pro"
    case ipadMini = "iPad Mini"
    case desktopCompact = "Desktop Compact"
    case desktopWide = "Desktop Wide"
    case custom = "Custom"

    var id: String { rawValue }

    var size: CGSize {
        switch self {
        case .iphoneSE: return CGSize(width: 375, height: 667)
        case .iphonePro: return CGSize(width: 393, height: 750)
        case .ipadMini: return CGSize(width: 744, height: 850)
        case .desktopCompact: return CGSize(width: 800, height: 600)
        case .desktopWide: return CGSize(width: 1050, height: 720)
        case .custom: return CGSize(width: 500, height: 700)
        }
    }

    var iconName: String {
        switch self {
        case .iphoneSE: return "iphone"
        case .iphonePro: return "iphone.gen3"
        case .ipadMini: return "ipad"
        case .desktopCompact: return "display"
        case .desktopWide: return "macwindow"
        case .custom: return "slider.horizontal.3"
        }
    }

    var userAgent: String {
        switch self {
        case .iphoneSE, .iphonePro:
            return "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"
        case .ipadMini:
            return "Mozilla/5.0 (iPad; CPU OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"
        case .desktopCompact, .desktopWide, .custom:
            return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15"
        }
    }

    var isMobile: Bool {
        switch self {
        case .iphoneSE, .iphonePro, .ipadMini: return true
        default: return false
        }
    }
}

enum WebBarZoomCommand: Equatable {
    case zoomIn
    case zoomOut
    case reset
}

/// Resolves browser-style zoom shortcuts without depending on the current
/// keyboard layout. Shift is deliberately ignored so both Command-= and the
/// customary Command-+ reach zoom in.
enum WebBarZoomShortcut {
    static func command(forKeyCode keyCode: UInt16,
                        hasCommand: Bool,
                        hasControl: Bool,
                        hasOption: Bool) -> WebBarZoomCommand? {
        guard hasCommand, !hasControl, !hasOption else { return nil }

        switch keyCode {
        case 24, 69: return .zoomIn      // ANSI =/+ and keypad +
        case 27, 78: return .zoomOut     // ANSI - and keypad -
        case 29, 82: return .reset       // ANSI 0 and keypad 0
        default: return nil
        }
    }
}

enum WebBarQuickAppCategory: String, Codable, CaseIterable {
    case ai
    case tools
    case social
}

struct WebBarQuickApp: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let urlString: String
    let category: WebBarQuickAppCategory
    let iconSymbol: String
    let colorHex: String
    let defaultViewport: WebBarViewportMode
    let description: String
}

struct WebBarQuickAppPresets {
    static let catalog: [WebBarQuickApp] = [
        // AI Assistants
        WebBarQuickApp(
            id: "chatgpt",
            name: "ChatGPT",
            urlString: "https://chatgpt.com",
            category: .ai,
            iconSymbol: "bubble.left.and.sparkles.fill",
            colorHex: "#10A37F",
            defaultViewport: .iphoneSE,
            description: "OpenAI conversational assistant"
        ),
        WebBarQuickApp(
            id: "claude",
            name: "Claude",
            urlString: "https://claude.ai",
            category: .ai,
            iconSymbol: "brain.head.profile",
            colorHex: "#D97706",
            defaultViewport: .iphoneSE,
            description: "Anthropic Claude AI"
        ),
        WebBarQuickApp(
            id: "gemini",
            name: "Gemini",
            urlString: "https://gemini.google.com",
            category: .ai,
            iconSymbol: "sparkles",
            colorHex: "#3B82F6",
            defaultViewport: .iphoneSE,
            description: "Google Gemini AI"
        ),
        WebBarQuickApp(
            id: "perplexity",
            name: "Perplexity",
            urlString: "https://www.perplexity.ai",
            category: .ai,
            iconSymbol: "magnifyingglass.circle.fill",
            colorHex: "#0D9488",
            defaultViewport: .iphoneSE,
            description: "AI-powered search engine"
        ),
        WebBarQuickApp(
            id: "deepseek",
            name: "DeepSeek",
            urlString: "https://chat.deepseek.com",
            category: .ai,
            iconSymbol: "atom",
            colorHex: "#4F46E5",
            defaultViewport: .iphoneSE,
            description: "DeepSeek conversational AI"
        ),

        // Productivity & Dev
        WebBarQuickApp(
            id: "zalo",
            name: "Zalo Web",
            urlString: "https://chat.zalo.me",
            category: .social,
            iconSymbol: "message.badge.filled.fill",
            colorHex: "#0068FF",
            defaultViewport: .iphoneSE,
            description: "Zalo messaging & chats"
        ),
        WebBarQuickApp(
            id: "translate",
            name: "Google Translate",
            urlString: "https://translate.google.com",
            category: .tools,
            iconSymbol: "character.book.closed.fill",
            colorHex: "#2563EB",
            defaultViewport: .iphoneSE,
            description: "Real-time multilingual translation"
        ),
        WebBarQuickApp(
            id: "github",
            name: "GitHub",
            urlString: "https://github.com",
            category: .tools,
            iconSymbol: "chevron.left.forwardslash.chevron.right",
            colorHex: "#24292F",
            defaultViewport: .iphoneSE,
            description: "Repositories and pull requests"
        ),
        WebBarQuickApp(
            id: "notion",
            name: "Notion",
            urlString: "https://www.notion.so",
            category: .tools,
            iconSymbol: "doc.text.fill",
            colorHex: "#37352F",
            defaultViewport: .iphoneSE,
            description: "Connected workspace for notes"
        ),

        // Social & Media
        WebBarQuickApp(
            id: "messenger",
            name: "Messenger",
            urlString: "https://www.facebook.com/messages",
            category: .social,
            iconSymbol: "paperplane.fill",
            colorHex: "#A855F7",
            defaultViewport: .iphoneSE,
            description: "Meta Messenger chats"
        ),
        WebBarQuickApp(
            id: "youtube",
            name: "YouTube",
            urlString: "https://m.youtube.com",
            category: .social,
            iconSymbol: "play.rectangle.fill",
            colorHex: "#EF4444",
            defaultViewport: .iphoneSE,
            description: "Videos and live streams"
        ),
        WebBarQuickApp(
            id: "x",
            name: "X (Twitter)",
            urlString: "https://x.com",
            category: .social,
            iconSymbol: "bubble.left.and.bubble.right.fill",
            colorHex: "#000000",
            defaultViewport: .iphoneSE,
            description: "Breaking news and social feed"
        )
    ]
}

struct WebBarTab: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var urlString: String
    var viewport: WebBarViewportMode = .iphoneSE
    var zoomLevel: Double = 1.0
    var isPinned: Bool = false
    var faviconUrl: String? = nil
    var unreadCount: Int = 0
    var createdAt: Date = Date()
}

struct WebBarDocument: Codable, Equatable {
    var tabs: [WebBarTab] = []
    var selectedTabID: UUID = UUID()
    var windowOpacity: Double = 1.0
    var isPinned: Bool = false
    var autoPauseMedia: Bool = true
    var enableAdBlock: Bool = true
    var customWidth: Double = 393
    var customHeight: Double = 750

    static var defaultDocument: WebBarDocument {
        let initialTab = WebBarTab(
            title: "New Tab",
            urlString: "",
            viewport: .iphoneSE
        )
        return WebBarDocument(
            tabs: [initialTab],
            selectedTabID: initialTab.id,
            windowOpacity: 1.0,
            isPinned: false,
            autoPauseMedia: true,
            enableAdBlock: true,
            customWidth: 393,
            customHeight: 750
        )
    }
}
