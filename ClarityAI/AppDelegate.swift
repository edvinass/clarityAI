import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var resultPanel: RefinementResultPanel?
    private let appModel = AppModel.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupMenuBar()
        setupHotkey()
        registerServices()
        appModel.requestAccessibilityPermission()
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.unregister()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "text.badge.checkmark", accessibilityDescription: "ClarityAI")
            button.toolTip = "ClarityAI — refine selected text in place"
        }

        let menu = NSMenu()

        let refineItem = NSMenuItem(title: "Refine Selection", action: #selector(refineSelection), keyEquivalent: "")
        refineItem.target = self
        menu.addItem(refineItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit ClarityAI", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    private func setupHotkey() {
        HotkeyManager.shared.onHotkey = { [weak self] in
            self?.refineSelection()
        }
        HotkeyManager.shared.register()
    }

    private func registerServices() {
        NSApp.servicesProvider = self
        NSUpdateDynamicServices()
    }

    @objc private func refineSelection() {
        Task { @MainActor in
            await appModel.refineCurrentSelection()
        }
    }

    @objc private func openSettings() {
        MainActor.assumeIsolated {
            SettingsWindowController.shared.show()
        }
    }
}

extension AppDelegate {
    @objc func refineText(
        _ pasteboard: NSPasteboard,
        userData: String,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) -> Bool {
        guard let text = pasteboard.string(forType: .string), !text.isEmpty else {
            error.pointee = "No text was provided to refine." as NSString
            return false
        }

        let semaphore = DispatchSemaphore(value: 0)
        var refinedText: String?
        var refinementError: Error?

        Task {
            do {
                refinedText = try await appModel.refinementCoordinator.refineText(text)
            } catch {
                refinementError = error
            }
            semaphore.signal()
        }

        semaphore.wait()

        if let refinementError {
            error.pointee = refinementError.localizedDescription as NSString
            return false
        }

        guard let refinedText else {
            error.pointee = "Refinement returned no text." as NSString
            return false
        }

        pasteboard.clearContents()
        pasteboard.setString(refinedText, forType: .string)
        return true
    }
}
