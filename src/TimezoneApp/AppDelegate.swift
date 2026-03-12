import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var shared: AppDelegate?

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
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
    }

    func updateStatusItem(title: String?) {
        statusItem.button?.title = (title?.isEmpty == false) ? title! : "🕐"
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
