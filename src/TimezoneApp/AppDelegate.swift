import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var shared: AppDelegate?

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private var menubarRefreshTimer: Timer?
    var viewModel: TimezoneViewModel? {
        didSet { updatePopoverContent() }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.shared = self
        if viewModel == nil {
            viewModel = .shared
        }
        configurePopover()
        configureStatusItem()
        startMenubarRefreshTimer()
    }

    func updateStatusItem(title: String?) {
        guard let button = statusItem.button else {
            return
        }

        guard let title, !title.isEmpty else {
            button.attributedTitle = NSAttributedString(string: "🕐")
            return
        }

        button.attributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
                .foregroundColor: NSColor.white.withAlphaComponent(0.8)
            ]
        )
    }

    @objc
    private func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            popover.performClose(sender)
            return
        }

        guard let button = statusItem.button else {
            return
        }

        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    private func configurePopover() {
        popover.animates = true
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 370, height: 560)
        updatePopoverContent()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.title = "🕐"
        button.target = self
        button.action = #selector(togglePopover(_:))
    }

    private func startMenubarRefreshTimer() {
        menubarRefreshTimer?.invalidate()
        menubarRefreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.viewModel?.refreshMenubarTitle()
            }
        }
        menubarRefreshTimer?.tolerance = 5
        viewModel?.refreshMenubarTitle()
    }

    private func updatePopoverContent() {
        guard let viewModel else {
            return
        }

        popover.contentViewController = NSHostingController(
            rootView: PopoverView()
                .environmentObject(viewModel)
        )
    }
}
