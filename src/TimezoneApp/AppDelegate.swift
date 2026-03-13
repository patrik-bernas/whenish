import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var shared: AppDelegate?

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var panel: NSPanel?
    private var globalClickMonitor: Any?
    private var localClickMonitor: Any?
    private var menubarRefreshTimer: Timer?
    var viewModel: TimezoneViewModel? {
        didSet { configurePanelContent() }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.shared = self
        if viewModel == nil {
            viewModel = .shared
        }
        configurePanel()
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

    // MARK: - Private

    @objc
    private func togglePanel(_ sender: AnyObject?) {
        guard let panel else { return }

        if panel.isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    private func showPanel() {
        guard let panel, let button = statusItem.button, let buttonWindow = button.window else {
            return
        }

        // Position the panel below the status item, centered on the button
        let buttonRect = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        let panelWidth = panel.frame.width
        let panelHeight = panel.frame.height
        let x = buttonRect.midX - panelWidth / 2
        let y = buttonRect.minY - panelHeight - 4
        panel.setFrameOrigin(NSPoint(x: x, y: y))

        // Set initial state for animation
        panel.alphaValue = 0
        panel.contentView?.wantsLayer = true

        panel.makeKeyAndOrderFront(nil)

        // Animate in: fade + subtle scale
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }

        installClickMonitors()
    }

    private func hidePanel() {
        guard let panel else { return }

        viewModel?.isSettingsOpen = false
        removeClickMonitors()

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.panel?.orderOut(nil)
            self?.panel?.alphaValue = 1
        })
    }

    private func configurePanel() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 390, height: 500),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.appearance = NSAppearance(named: .darkAqua)
        panel.isMovableByWindowBackground = false

        self.panel = panel
        configurePanelContent()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.title = "🕐"
        button.target = self
        button.action = #selector(togglePanel(_:))
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

    private func configurePanelContent() {
        guard let panel, let viewModel else {
            return
        }

        // 1. Create the NSVisualEffectView for glass background
        let visualEffect = NSVisualEffectView(frame: panel.contentView!.bounds)
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        visualEffect.blendingMode = .behindWindow
        visualEffect.autoresizingMask = [.width, .height]
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 18
        visualEffect.layer?.masksToBounds = true

        // 2. Create the SwiftUI hosting view with transparent background
        let hostingView = NSHostingView(
            rootView: PopoverView()
                .environmentObject(viewModel)
        )
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = .clear

        // 3. Layer the hosting view on top of the visual effect view
        visualEffect.addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: visualEffect.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor),
        ])

        // 4. Set the content view
        panel.contentView = visualEffect
    }

    // MARK: - Click-outside-to-close

    private func installClickMonitors() {
        // Global monitor: clicks outside the app
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.hidePanel()
        }
        // Local monitor: clicks on the status item while panel is open
        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self, let panel = self.panel, panel.isVisible else { return event }

            // If the click is on the status item button, let togglePanel handle it
            if let button = self.statusItem.button,
               let buttonWindow = button.window,
               event.window == buttonWindow {
                return event
            }

            // If the click is inside the panel, let it through
            if event.window == panel {
                return event
            }

            // Click somewhere else in the app — close the panel
            self.hidePanel()
            return event
        }
    }

    private func removeClickMonitors() {
        if let monitor = globalClickMonitor {
            NSEvent.removeMonitor(monitor)
            globalClickMonitor = nil
        }
        if let monitor = localClickMonitor {
            NSEvent.removeMonitor(monitor)
            localClickMonitor = nil
        }
    }
}
