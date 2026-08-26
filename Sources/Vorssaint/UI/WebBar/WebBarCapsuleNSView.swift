// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit

final class WebBarCapsuleNSView: NSView {
    weak var service: WebBarService?
    private var trackingArea: NSTrackingArea?
    private var hoveredIndex: Int? = nil
    private var tabWebIcons: [String: NSImage] = [:]

    private var isDragging: Bool = false
    private var dragCandidateIndex: Int? = nil
    private var draggedTabIndex: Int? = nil
    private var mouseDownLocation: NSPoint = .zero
    private var currentDragLocation: NSPoint = .zero
    private var isMarkedForDeletion: Bool = false

    private let itemWidth: CGFloat = 28
    private let itemHeight: CGFloat = 22
    private let iconSize: CGFloat = 21.0
    private let itemSpacing: CGFloat = 4.0
    private let capsulePaddingH: CGFloat = 4.0

    init(service: WebBarService) {
        self.service = service
        super.init(frame: .zero)
        self.wantsLayer = true
        updateCapsuleLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var totalCapsuleWidth: CGFloat {
        guard let service = service else { return bounds.width }
        let webTabs = service.document.tabs.filter { !$0.urlString.isEmpty }
        let totalCount = webTabs.count + 1
        let tabsTotalWidth = (CGFloat(totalCount) * itemWidth) + (CGFloat(totalCount - 1) * itemSpacing)
        return (capsulePaddingH * 2) + tabsTotalWidth
    }

    func updateCapsuleLayout() {
        let totalWidth = totalCapsuleWidth
        let totalHeight: CGFloat = 24

        let newFrame = NSRect(x: 0, y: 0, width: totalWidth, height: totalHeight)
        if self.frame != newFrame {
            self.frame = newFrame
            service?.setCapsuleStatusItemLength(totalWidth)
        }

        setupTrackingArea()
        needsDisplay = true
    }

    func tabCenterRelativeX(for tabId: UUID?) -> CGFloat {
        guard let service = service else { return itemWidth / 2.0 }
        let webTabs = service.document.tabs.filter { !$0.urlString.isEmpty }
        let index: Int
        if let tabId = tabId, let found = webTabs.firstIndex(where: { $0.id == tabId }) {
            index = found
        } else {
            index = webTabs.count
        }
        let itemX = capsulePaddingH + (CGFloat(index) * (itemWidth + itemSpacing))
        return itemX + (itemWidth / 2.0)
    }

    private func setupTrackingArea() {
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        self.trackingArea = area
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        setupTrackingArea()
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext, let service = service else { return }

        let bounds = self.bounds
        let midY = bounds.height / 2.0

        let startX = capsulePaddingH
        let webTabs = service.document.tabs.filter { !$0.urlString.isEmpty }
        let selectedTabId = service.document.selectedTabID
        let isBlankActive = service.activeTab?.urlString.isEmpty == true
        let targetDropIdx = isDragging && !isMarkedForDeletion ? targetDropIndex(for: currentDragLocation.x) : nil

        let isPanelOpen = service.isVisible

        // 1. Draw web tabs
        for (index, tab) in webTabs.enumerated() {
            if isDragging && index == draggedTabIndex {
                continue
            }

            var visualIndex = CGFloat(index)
            if let draggedIdx = draggedTabIndex, let targetIdx = targetDropIdx {
                if draggedIdx < targetIdx && index > draggedIdx && index <= targetIdx {
                    visualIndex -= 1.0
                } else if draggedIdx > targetIdx && index >= targetIdx && index < draggedIdx {
                    visualIndex += 1.0
                }
            }

            let itemX = startX + (visualIndex * (itemWidth + itemSpacing))
            let tabRect = NSRect(
                x: itemX,
                y: midY - (itemHeight / 2.0),
                width: itemWidth,
                height: itemHeight
            )
            let isDraggedGhost = (isDragging && draggedTabIndex == index)
            let isSelected = isPanelOpen && (tab.id == selectedTabId) && !isBlankActive && !isDraggedGhost
            let isHovered = (hoveredIndex == index && !isDragging)

            if isSelected || isHovered {
                drawLiquidGlassPill(in: tabRect, isSelected: isSelected, ctx: ctx)
            }

            let tabKey = tab.id.uuidString + "_" + tab.urlString + "_" + (tab.faviconUrl ?? "")
            let iconRect = NSRect(
                x: tabRect.midX - (iconSize / 2.0),
                y: midY - (iconSize / 2.0),
                width: iconSize,
                height: iconSize
            )

            let alpha: CGFloat = isDraggedGhost ? 0.22 : (isSelected ? 1.0 : (isHovered ? 0.92 : 0.65))
            ctx.saveGState()
            ctx.setAlpha(alpha)
            drawTabIcon(for: tab, key: tabKey, in: iconRect)
            ctx.restoreGState()

            if isSelected {
                let dotRadius: CGFloat = 1.75
                let dotCenter = CGPoint(x: tabRect.midX, y: 1.8)
                ctx.addEllipse(in: CGRect(x: dotCenter.x - dotRadius, y: dotCenter.y - dotRadius, width: dotRadius * 2, height: dotRadius * 2))
                ctx.setFillColor(NSColor.white.withAlphaComponent(0.95).cgColor)
                ctx.fillPath()
            }

            if tab.unreadCount > 0 && UserDefaults.standard.bool(forKey: DefaultsKey.webBarNotificationBadges) {
                let badgeRadius: CGFloat = 3.5
                let badgeCenter = CGPoint(x: iconRect.maxX - 0.5, y: iconRect.maxY - 0.5)
                let badgeRect = CGRect(x: badgeCenter.x - badgeRadius, y: badgeCenter.y - badgeRadius, width: badgeRadius * 2, height: badgeRadius * 2)

                ctx.saveGState()
                ctx.setShadow(offset: CGSize(width: 0, height: 0), blur: 3.0, color: NSColor.systemRed.withAlphaComponent(0.85).cgColor)
                ctx.addEllipse(in: badgeRect)
                ctx.setFillColor(NSColor.systemRed.cgColor)
                ctx.fillPath()
                ctx.restoreGState()

                ctx.addEllipse(in: badgeRect)
                ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.95).cgColor)
                ctx.setLineWidth(1.0)
                ctx.strokePath()
            }
        }

        // 2. Draw [+] Button at the end
        let plusIndex = webTabs.count
        let plusItemX = startX + (CGFloat(plusIndex) * (itemWidth + itemSpacing))
        let plusTabRect = NSRect(
            x: plusItemX,
            y: midY - (itemHeight / 2.0),
            width: itemWidth,
            height: itemHeight
        )
        let isPlusSelected = isPanelOpen && isBlankActive
        let isPlusHovered = (hoveredIndex == plusIndex && !isDragging)

        if isPlusSelected || isPlusHovered {
            drawLiquidGlassPill(in: plusTabRect, isSelected: isPlusSelected, ctx: ctx)
        }

        let plusIconRect = NSRect(
            x: plusTabRect.midX - (iconSize / 2.0),
            y: midY - (iconSize / 2.0),
            width: iconSize,
            height: iconSize
        )

        let plusAlpha: CGFloat = isPlusSelected ? 1.0 : (isPlusHovered ? 0.92 : 0.70)
        ctx.saveGState()
        ctx.setAlpha(plusAlpha)
        if let cachedPlus = tabWebIcons["__permanent_plus_squircle__"] {
            cachedPlus.draw(in: plusIconRect)
        } else {
            let blankTabDummy = WebBarTab(title: "New Tab", urlString: "")
            WebBarFaviconManager.shared.getDirectWebIcon(for: blankTabDummy, size: NSSize(width: 48, height: 48)) { [weak self] img in
                self?.tabWebIcons["__permanent_plus_squircle__"] = img
                self?.needsDisplay = true
            }
        }
        ctx.restoreGState()

        if isPlusSelected {
            let dotRadius: CGFloat = 1.75
            let dotCenter = CGPoint(x: plusTabRect.midX, y: 1.8)
            ctx.addEllipse(in: CGRect(x: dotCenter.x - dotRadius, y: dotCenter.y - dotRadius, width: dotRadius * 2, height: dotRadius * 2))
            ctx.setFillColor(NSColor.white.withAlphaComponent(0.95).cgColor)
            ctx.fillPath()
        }
    }

    private func drawLiquidGlassPill(in rect: NSRect, isSelected: Bool, ctx: CGContext) {
        let tileSide: CGFloat = 22.0
        let tileRect = NSRect(
            x: rect.midX - (tileSide / 2.0),
            y: rect.midY - (tileSide / 2.0),
            width: tileSide,
            height: tileSide
        )
        let tileRadius: CGFloat = 6.0
        let tilePath = CGPath(roundedRect: tileRect, cornerWidth: tileRadius, cornerHeight: tileRadius, transform: nil)

        ctx.saveGState()

        if isSelected {
            ctx.saveGState()
            ctx.setShadow(offset: CGSize(width: 0, height: -1.0), blur: 3.5, color: NSColor.black.withAlphaComponent(0.35).cgColor)
            ctx.addPath(tilePath)
            ctx.setFillColor(NSColor.white.withAlphaComponent(0.18).cgColor)
            ctx.fillPath()
            ctx.restoreGState()

            ctx.addPath(tilePath)
            ctx.setFillColor(NSColor.white.withAlphaComponent(0.28).cgColor)
            ctx.fillPath()

            let colors = [
                NSColor.white.withAlphaComponent(0.55).cgColor,
                NSColor.white.withAlphaComponent(0.22).cgColor,
                NSColor.white.withAlphaComponent(0.04).cgColor
            ] as CFArray
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 0.45, 1.0]) {
                ctx.saveGState()
                ctx.addPath(tilePath)
                ctx.clip()
                ctx.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: tileRect.midX, y: tileRect.maxY),
                    end: CGPoint(x: tileRect.midX, y: tileRect.minY),
                    options: []
                )
                ctx.restoreGState()
            }

            ctx.addPath(tilePath)
            ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.60).cgColor)
            ctx.setLineWidth(0.85)
            ctx.strokePath()

            let bottomGlowRect = CGRect(x: tileRect.minX + 3.0, y: tileRect.minY + 1.2, width: tileRect.width - 6.0, height: 1.0)
            ctx.addEllipse(in: bottomGlowRect)
            ctx.setFillColor(NSColor.white.withAlphaComponent(0.40).cgColor)
            ctx.fillPath()
        } else {
            ctx.addPath(tilePath)
            ctx.setFillColor(NSColor.white.withAlphaComponent(0.12).cgColor)
            ctx.fillPath()

            ctx.addPath(tilePath)
            ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.22).cgColor)
            ctx.setLineWidth(0.6)
            ctx.strokePath()
        }

        ctx.restoreGState()
    }

    private func drawTabIcon(for tab: WebBarTab, key: String, in iconRect: NSRect) {
        if let cachedIcon = tabWebIcons[key] {
            cachedIcon.draw(in: iconRect)
        } else {
            WebBarFaviconManager.shared.getDirectWebIcon(for: tab) { [weak self] downloadedIcon in
                self?.tabWebIcons[key] = downloadedIcon
                self?.needsDisplay = true
            }

            if tab.urlString.isEmpty, let img = NSImage(systemSymbolName: "sparkles", accessibilityDescription: nil) {
                img.draw(in: iconRect)
            } else if let img = NSImage(systemSymbolName: "globe", accessibilityDescription: nil) {
                img.draw(in: iconRect)
            }
        }
    }

    // MARK: - Mouse Event Handling

    override func mouseDown(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        mouseDownLocation = loc
        dragCandidateIndex = hitIndex(for: loc)
        isDragging = false
        draggedTabIndex = nil
        isMarkedForDeletion = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard let candidate = dragCandidateIndex, candidate >= 0 else { return }
        let loc = convert(event.locationInWindow, from: nil)
        currentDragLocation = loc

        let dx = loc.x - mouseDownLocation.x
        let dy = loc.y - mouseDownLocation.y
        let distance = hypot(dx, dy)

        if !isDragging && distance > 6.0 {
            isDragging = true
            draggedTabIndex = candidate
            NSCursor.closedHand.set()
        }

        if isDragging, let dragIdx = draggedTabIndex, let service = service {
            let webTabs = service.document.tabs.filter { !$0.urlString.isEmpty }
            if dragIdx < webTabs.count {
                let wasMarked = isMarkedForDeletion
                isMarkedForDeletion = isOutsideCapsule(loc)
                if isMarkedForDeletion != wasMarked {
                    if isMarkedForDeletion {
                        NSCursor.disappearingItem.set()
                    } else {
                        NSCursor.closedHand.set()
                    }
                }
            }
            needsDisplay = true
        }
    }

    override func mouseUp(with event: NSEvent) {
        NSCursor.arrow.set()
        guard let service = service else { return }
        let loc = convert(event.locationInWindow, from: nil)

        if isDragging {
            let webTabs = service.document.tabs.filter { !$0.urlString.isEmpty }
            if isMarkedForDeletion {
                if let dragIdx = draggedTabIndex, dragIdx < webTabs.count {
                    let tabToDelete = webTabs[dragIdx]
                    service.closeTab(id: tabToDelete.id)
                }
            } else {
                if let sourceIdx = draggedTabIndex {
                    let destIdx = targetDropIndex(for: loc.x, sourceIdx: sourceIdx)
                    if sourceIdx != destIdx && sourceIdx < service.document.tabs.count && destIdx < service.document.tabs.count {
                        let moved = service.document.tabs.remove(at: sourceIdx)
                        service.document.tabs.insert(moved, at: destIdx)
                    }
                }
            }

            isDragging = false
            draggedTabIndex = nil
            dragCandidateIndex = nil
            isMarkedForDeletion = false
            needsDisplay = true
            return
        }

        let clickedTarget = hitIndex(for: loc)
        let webTabs = service.document.tabs.filter { !$0.urlString.isEmpty }

        if let index = clickedTarget {
            if index < webTabs.count {
                let tab = webTabs[index]
                if service.isVisible && service.document.selectedTabID == tab.id && service.activeTab?.urlString.isEmpty == false {
                    service.hide()
                } else {
                    service.selectTab(id: tab.id)
                    service.show(for: tab.id)
                }
            } else if index == webTabs.count {
                // Clicked [+] New Tab
                if service.isVisible && service.activeTab?.urlString.isEmpty == true {
                    service.hide()
                } else if let blankTab = service.document.tabs.first(where: { $0.urlString.isEmpty }) {
                    service.selectTab(id: blankTab.id)
                    service.show(for: blankTab.id)
                } else {
                    service.addNewTab()
                    service.show(for: service.document.selectedTabID)
                }
            }
        }

        dragCandidateIndex = nil
        isDragging = false
        needsDisplay = true
    }

    override func rightMouseDown(with event: NSEvent) {
        guard let service = service else { return }
        let loc = convert(event.locationInWindow, from: nil)
        let clickedTarget = hitIndex(for: loc)
        let webTabs = service.document.tabs.filter { !$0.urlString.isEmpty }

        let menu = NSMenu()
        if let index = clickedTarget, index < webTabs.count {
            let tab = webTabs[index]
            menu.addItem(NSMenuItem(title: tab.title.isEmpty ? "Tab" : tab.title, action: nil, keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Reload", action: #selector(service.menuActionReload), keyEquivalent: "r"))
            menu.addItem(NSMenuItem(title: "Close Tab", action: #selector(service.menuActionCloseActiveTab), keyEquivalent: "w"))
            menu.addItem(NSMenuItem.separator())
        }
        menu.addItem(NSMenuItem(title: "New Tab", action: #selector(service.menuActionNewTab), keyEquivalent: "t"))
        menu.addItem(NSMenuItem(title: "Quick Apps & AI", action: #selector(service.menuActionOpenQuickApps), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "WebBar Settings...", action: #selector(service.menuActionOpenSettings), keyEquivalent: ","))

        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    override func mouseMoved(with event: NSEvent) {
        let loc = convert(event.locationInWindow, from: nil)
        let newHover = hitIndex(for: loc)
        if newHover != hoveredIndex {
            hoveredIndex = newHover
            needsDisplay = true
        }
    }

    override func mouseExited(with event: NSEvent) {
        hoveredIndex = nil
        needsDisplay = true
    }

    private func targetDropIndex(for locX: CGFloat, sourceIdx: Int? = nil) -> Int {
        guard let service = service else { return 0 }
        let webTabs = service.document.tabs.filter { !$0.urlString.isEmpty }
        let tabsCount = webTabs.count
        guard tabsCount > 0 else { return 0 }

        let startX = capsulePaddingH
        let totalPerItem = itemWidth + itemSpacing

        guard let source = sourceIdx else {
            let relativeX = locX - startX
            let calculated = Int(round(relativeX / totalPerItem))
            return max(0, min(tabsCount - 1, calculated))
        }

        let currentSlotCenter = startX + (CGFloat(source) * totalPerItem) + (itemWidth / 2.0)
        let deltaX = locX - currentSlotCenter
        let threshold = totalPerItem * 0.55

        if abs(deltaX) < threshold {
            return source
        }

        let slotOffset = Int(round(deltaX / totalPerItem))
        let target = source + slotOffset
        return max(0, min(tabsCount - 1, target))
    }

    private func isOutsideCapsule(_ loc: NSPoint) -> Bool {
        let dragAllowance = NSRect(x: -30, y: -45, width: bounds.width + 60, height: bounds.height + 70)
        return !dragAllowance.contains(loc)
    }

    private func hitIndex(for loc: NSPoint) -> Int? {
        guard let service = service else { return nil }
        let startX = capsulePaddingH
        let webTabs = service.document.tabs.filter { !$0.urlString.isEmpty }
        let totalCount = webTabs.count + 1
        for i in 0..<totalCount {
            let tabRect = NSRect(
                x: startX + (CGFloat(i) * (itemWidth + itemSpacing)),
                y: 0,
                width: itemWidth + itemSpacing,
                height: bounds.height
            )
            if tabRect.contains(loc) {
                return i
            }
        }
        return nil
    }
}
