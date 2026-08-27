// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import SwiftUI

final class WebBarTabDragOverlay: ObservableObject {
    static let shared = WebBarTabDragOverlay()

    @Published var tabTitle: String = ""
    @Published var tabFavicon: NSImage? = nil
    @Published var isMarkedForDeletion: Bool = false

    private var panel: NSPanel?

    private init() {}

    func startDrag(tab: WebBarTab, favicon: NSImage?, at screenPoint: NSPoint) {
        tabTitle = tab.title.isEmpty ? (URL(string: tab.urlString)?.host ?? "Tab") : tab.title
        tabFavicon = favicon
        isMarkedForDeletion = false

        if panel == nil {
            let p = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 36, height: 36),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            p.isOpaque = false
            p.backgroundColor = .clear
            p.hasShadow = false
            p.level = .popUpMenu
            p.ignoresMouseEvents = true
            p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

            let host = NSHostingController(rootView: WebBarDragOverlayView(overlay: self))
            p.contentViewController = host
            panel = p
        }

        updatePosition(screenPoint: screenPoint)
        panel?.alphaValue = 0
        panel?.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.12
            panel?.animator().alphaValue = 1.0
        }
    }

    func updatePosition(screenPoint: NSPoint) {
        guard let panel = panel else { return }
        let size = panel.frame.size
        let x = screenPoint.x - (size.width / 2.0)
        let y = screenPoint.y - (size.height / 2.0) - 2
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    func updateState(isMarkedForDeletion: Bool) {
        if self.isMarkedForDeletion != isMarkedForDeletion {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.72)) {
                self.isMarkedForDeletion = isMarkedForDeletion
            }
        }
    }

    func endDrag(completed: Bool) {
        guard let panel = panel else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.12
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            panel.orderOut(nil)
            self?.panel = nil
        })
    }
}

struct WebBarDragOverlayView: View {
    @ObservedObject var overlay: WebBarTabDragOverlay

    var body: some View {
        ZStack {
            if overlay.isMarkedForDeletion {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(nsColor: .systemRed))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.6), lineWidth: 1)
                    )
                    .overlay(
                        Image(systemName: "trash.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .frame(width: 24, height: 24)
                    .shadow(color: Color.red.opacity(0.65), radius: 5, y: 1.5)
                    .scaleEffect(1.05)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
            } else {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
                    )
                    .overlay(
                        Group {
                            if let img = overlay.tabFavicon {
                                Image(nsImage: img)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 15, height: 15)
                                    .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                            } else {
                                Image(systemName: "globe")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.primary)
                            }
                        }
                    )
                    .frame(width: 24, height: 24)
                    .shadow(color: .black.opacity(0.4), radius: 4, y: 1.5)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
            }
        }
        .frame(width: 36, height: 36)
    }
}
