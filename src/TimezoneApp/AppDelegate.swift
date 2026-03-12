import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()

    func applicationDidFinishLaunching(_ notification: Notification) {
        configurePopover()
        configureStatusItem()
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
        popover.contentSize = NSSize(width: 370, height: 520)
        popover.contentViewController = NSHostingController(rootView: PlaceholderPopoverView())
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.title = "🕐"
        button.target = self
        button.action = #selector(togglePopover(_:))
    }
}

private struct PlaceholderPopoverView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Timezone Converter")
                .font(.headline)
            Text("Popover shell placeholder")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}
