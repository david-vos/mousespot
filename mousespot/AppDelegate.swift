import Carbon.HIToolbox
import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var overlay: OverlayWindow!
    private var hotKey: HotKey?
    private var settingsWindow: NSWindow?
    private var observer: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let symbol = NSImage(systemSymbolName: "scope", accessibilityDescription: "MouseSpot") {
            statusItem.button?.image = symbol
        } else {
            statusItem.button?.title = "⌖"
        }
        statusItem.menu = buildMenu()

        overlay = OverlayWindow()

        registerHotKey()

        observer = NotificationCenter.default.addObserver(
            forName: SpotSettings.changed,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.registerHotKey()
            self?.applyLocalization()
        }
    }

    private func registerHotKey() {
        let s = SpotSettings.shared
        hotKey = nil
        hotKey = HotKey(
            keyCode: s.hotKeyCode,
            modifiers: s.hotKeyModifiers
        ) { [weak self] in
            self?.overlay.toggleTracking()
        }
    }

    deinit {
        observer.map(NotificationCenter.default.removeObserver)
    }

    private func applyLocalization() {
        statusItem.menu = buildMenu()
        settingsWindow?.title = t("settingsTitle")
    }

    private func buildMenu() -> NSMenu {
        let s = SpotSettings.shared
        let menu = NSMenu()
        menu.addItem(
            item(
                t("toggleCircle"),
                action: #selector(toggle(_:)),
                key: HotKeyCaptureView.menuKeyEquivalent(for: s.hotKeyCode),
                modifiers: HotKeyCaptureView.appKitModifiers(from: s.hotKeyModifiers)
            )
        )
        menu.addItem(
            item(
                t("settingsMenu"),
                action: #selector(openSettings(_:)),
                key: ",",
                modifiers: [.command]
            )
        )
        menu.addItem(.separator())
        menu.addItem(
            withTitle: t("quit"),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        return menu
    }

    private func item(
        _ title: String,
        action: Selector,
        key: String,
        modifiers: NSEvent.ModifierFlags
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.keyEquivalentModifierMask = modifiers
        item.target = self
        return item
    }

    @objc private func toggle(_ sender: Any?) {
        overlay.toggleTracking()
    }

    @objc private func openSettings(_ sender: Any?) {
        NSApp.activate(ignoringOtherApps: true)
        if settingsWindow == nil {
            let hosting = NSHostingController(rootView: SettingsView())
            let window = NSWindow(contentViewController: hosting)
            window.title = t("settingsTitle")
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
}
