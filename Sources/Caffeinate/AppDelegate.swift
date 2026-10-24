import AppKit
import CaffeinateCore
import Combine
import SwiftUI

@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate, NSWindowDelegate {
    private let controller = CaffeinateController()
    private let preferences = Preferences()
    private let popover = NSPopover()
    private var statusItem: NSStatusItem!
    private var subscription: AnyCancellable?
    private var panelSubscription: AnyCancellable?
    private var desktopPanel: NSPanel?

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        withExtendedLifetime(delegate) { app.run() }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "")
        if others.contains(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) {
            NSApp.terminate(nil)
            return
        }

        let applicationMenu = NSMenu()
        let openPanel = NSMenuItem(title: "Open Caffeinate", action: #selector(showPopover), keyEquivalent: ",")
        openPanel.target = self
        applicationMenu.addItem(openPanel)
        applicationMenu.addItem(.separator())
        applicationMenu.addItem(withTitle: "Quit Caffeinate", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let applicationMenuItem = NSMenuItem()
        applicationMenuItem.submenu = applicationMenu
        let mainMenu = NSMenu()
        mainMenu.addItem(applicationMenuItem)
        NSApp.mainMenu = mainMenu

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(statusItemClicked)
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        popover.contentViewController = NSHostingController(
            rootView: CaffeinateView(controller: controller, preferences: preferences)
        )

        subscription = controller.$session.sink { [weak self] session in
            self?.updateStatusItem(isRunning: session != nil)
        }
        panelSubscription = preferences.$showsDesktopPanel.removeDuplicates().sink { [weak self] visible in
            self?.setDesktopPanelVisible(visible)
        }

        if !UserDefaults.standard.bool(forKey: "hasOpenedBefore") {
            UserDefaults.standard.set(true, forKey: "hasOpenedBefore")
            showPopover()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showPopover()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller.stop()
    }

    func popoverWillShow(_ notification: Notification) {
        preferences.refreshLoginStatus()
    }

    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow === desktopPanel {
            preferences.showsDesktopPanel = false
        }
    }

    private func setDesktopPanelVisible(_ visible: Bool) {
        guard visible else {
            desktopPanel?.orderOut(nil)
            return
        }
        popover.performClose(nil)
        if desktopPanel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 272, height: 240),
                styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
                backing: .buffered, defer: false
            )
            panel.title = "Caffeinate"
            panel.titleVisibility = .hidden
            panel.titlebarAppearsTransparent = true
            panel.standardWindowButton(.closeButton)?.isHidden = true
            panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
            panel.standardWindowButton(.zoomButton)?.isHidden = true
            panel.isMovableByWindowBackground = true
            panel.isFloatingPanel = true
            panel.hidesOnDeactivate = false
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.isReleasedWhenClosed = false
            panel.delegate = self
            panel.contentViewController = NSHostingController(
                rootView: DesktopPanelView(controller: controller, preferences: preferences) { [weak self] in
                    self?.showPopover()
                }
            )
            panel.setContentSize(panel.contentViewController!.view.fittingSize)
            if !panel.setFrameUsingName("CaffeinateDesktopPanel") {
                panel.center()
            }
            panel.setFrameAutosaveName("CaffeinateDesktopPanel")
            desktopPanel = panel
        }
        desktopPanel?.orderFrontRegardless()
    }

    private func updateStatusItem(isRunning: Bool) {
        guard let button = statusItem?.button else { return }
        button.image = NSImage(
            systemSymbolName: isRunning ? "cup.and.saucer.fill" : "cup.and.saucer",
            accessibilityDescription: isRunning ? "Caffeinate: keeping your Mac awake" : "Caffeinate: resting"
        )
        button.image?.isTemplate = true
        button.toolTip = isRunning ? "Caffeinate · Awake" : "Caffeinate · Resting"
        button.setAccessibilityLabel(button.toolTip)
    }

    @objc private func statusItemClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showContextMenu()
        } else if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    @objc private func showPopover() {
        guard let button = statusItem?.button else { return }
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    private func showContextMenu() {
        popover.performClose(nil)
        let menu = NSMenu()
        let toggle = NSMenuItem(
            title: controller.isRunning ? "Let it rest" : "Keep awake",
            action: #selector(toggleSession), keyEquivalent: ""
        )
        toggle.target = self
        menu.addItem(toggle)
        let desktop = NSMenuItem(
            title: preferences.showsDesktopPanel ? "Hide desktop panel" : "Show desktop panel",
            action: #selector(toggleDesktopPanel), keyEquivalent: ""
        )
        desktop.target = self
        menu.addItem(desktop)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit Caffeinate", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func toggleSession() {
        if controller.isRunning {
            controller.stop()
        } else {
            controller.start(duration: preferences.duration)
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    @objc private func toggleDesktopPanel() {
        preferences.showsDesktopPanel.toggle()
    }
}
