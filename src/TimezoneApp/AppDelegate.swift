import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    static weak var shared: AppDelegate?

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var popover: NSPopover!
    private var menubarRefreshTimer: Timer?
    private var positioningView: NSView?

    var viewModel: TimezoneViewModel?

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
            button.title = "🕐"
            button.font = nil
            return
        }

        let font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        button.font = font
        button.title = title
    }

    func updateStatusItemTooltip(tooltip: String) {
        statusItem.button?.toolTip = tooltip
    }

    // MARK: - Popover

    private func configurePopover() {
        guard let viewModel else { return }

        popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        popover.contentSize = NSSize(width: 390, height: 500)

        let contentView = PopoverView()
            .environmentObject(viewModel)
        let hostingController = NSHostingController(rootView: contentView)
        popover.contentViewController = hostingController
    }

    @objc
    private func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }

        // Reset scrubber to "Now" every time the popover opens
        viewModel?.resetScrubber()

        // Arrow hiding trick:
        // 1. Create an invisible positioning view inside the button
        let posView = NSView(frame: button.bounds)
        posView.identifier = NSUserInterfaceItemIdentifier("positioningView")
        button.addSubview(posView)
        self.positioningView = posView

        // 2. Show the popover relative to this positioning view
        popover.show(relativeTo: posView.bounds, of: posView, preferredEdge: .minY)

        // 3. Move the positioning view off-screen so the arrow disappears
        posView.frame = NSRect(x: button.bounds.midX - 0.5, y: -200, width: 1, height: 1)
    }

    // MARK: - NSPopoverDelegate

    nonisolated func popoverDidClose(_ notification: Notification) {
        Task { @MainActor [weak self] in
            self?.positioningView?.removeFromSuperview()
            self?.positioningView = nil
        }
    }

    // MARK: - Status Item

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.title = "🕐"
        button.target = self
        button.action = #selector(togglePopover(_:))
    }

    // MARK: - Timer

    private func startMenubarRefreshTimer() {
        menubarRefreshTimer?.invalidate()

        // Update immediately
        viewModel?.refreshMenubarTitle()

        // Calculate delay until the next minute boundary (:00 seconds)
        let now = Date()
        let calendar = Calendar.current
        let seconds = calendar.component(.second, from: now)
        let nanoseconds = calendar.component(.nanosecond, from: now)
        let delayToNextMinute = Double(60 - seconds) - Double(nanoseconds) / 1_000_000_000

        // Fire once at the exact next minute, then repeat every 60s
        DispatchQueue.main.asyncAfter(deadline: .now() + delayToNextMinute) { [weak self] in
            Task { @MainActor [weak self] in
                self?.viewModel?.refreshMenubarTitle()
            }
            let timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.viewModel?.refreshMenubarTitle()
                }
            }
            RunLoop.main.add(timer, forMode: .common)
            self?.menubarRefreshTimer = timer
        }
    }
}
