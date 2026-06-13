import AppKit
import CoreGraphics
import Foundation

final class SyntheticPasteService {
    static let shared = SyntheticPasteService()

    private let pasteDelay: TimeInterval = 0.15

    private init() {}

    func captureSelection() -> String? {
        let pasteboard = NSPasteboard.general
        let savedContents = savePasteboard(pasteboard)

        pasteboard.clearContents()
        postCommandKey(keyCode: .c)

        Thread.sleep(forTimeInterval: pasteDelay)

        let copiedText = pasteboard.string(forType: .string)
        restorePasteboard(pasteboard, savedContents: savedContents)

        guard let copiedText, !copiedText.isEmpty else {
            return nil
        }

        return copiedText
    }

    func replaceSelection(with text: String) -> Bool {
        let pasteboard = NSPasteboard.general
        let savedContents = savePasteboard(pasteboard)

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        postCommandKey(keyCode: .v)

        Thread.sleep(forTimeInterval: pasteDelay)
        restorePasteboard(pasteboard, savedContents: savedContents)

        return true
    }

    func captureEntireField() -> String? {
        selectAll()
        Thread.sleep(forTimeInterval: pasteDelay)
        return captureSelection()
    }

    func replaceEntireField(with text: String) -> Bool {
        selectAll()
        Thread.sleep(forTimeInterval: pasteDelay)
        return replaceSelection(with: text)
    }

    func selectAll() {
        postCommandKey(keyCode: .a)
    }

    private func savePasteboard(_ pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType: Data]? {
        var saved: [NSPasteboard.PasteboardType: Data] = [:]

        for type in pasteboard.types ?? [] {
            if let data = pasteboard.data(forType: type) {
                saved[type] = data
            }
        }

        return saved.isEmpty ? nil : saved
    }

    private func restorePasteboard(
        _ pasteboard: NSPasteboard,
        savedContents: [NSPasteboard.PasteboardType: Data]?
    ) {
        pasteboard.clearContents()

        guard let savedContents else { return }

        for (type, data) in savedContents {
            pasteboard.setData(data, forType: type)
        }
    }

    private func postCommandKey(keyCode: KeyCode) {
        let source = CGEventSource(stateID: .hidSystemState)

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode.rawValue, keyDown: true)
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)

        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode.rawValue, keyDown: false)
        keyUp?.flags = .maskCommand
        keyUp?.post(tap: .cghidEventTap)
    }

    private enum KeyCode: CGKeyCode {
        case a = 0
        case c = 8
        case v = 9
    }
}
