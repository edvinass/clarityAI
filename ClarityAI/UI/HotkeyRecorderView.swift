import AppKit
import Carbon
import SwiftUI

struct HotkeyRecorderView: NSViewRepresentable {
    @Binding var config: HotkeyConfig

    func makeNSView(context: Context) -> HotkeyRecorderButton {
        let view = HotkeyRecorderButton()
        view.config = config
        view.onChange = { newConfig in
            config = newConfig
        }
        return view
    }

    func updateNSView(_ nsView: HotkeyRecorderButton, context: Context) {
        nsView.config = config
        nsView.refreshTitle()
    }
}

final class HotkeyRecorderButton: NSButton {
    var config: HotkeyConfig = .default
    var onChange: ((HotkeyConfig) -> Void)?

    private var isRecording = false {
        didSet { refreshTitle() }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        bezelStyle = .rounded
        setButtonType(.momentaryPushIn)
        target = self
        action = #selector(toggleRecording)
        refreshTitle()
    }

    func refreshTitle() {
        if isRecording {
            title = "Press shortcut… (Esc to cancel)"
        } else {
            title = config.displayString
        }
    }

    @objc private func toggleRecording() {
        isRecording.toggle()
        if isRecording {
            window?.makeFirstResponder(self)
        }
    }

    override var acceptsFirstResponder: Bool { true }

    override func resignFirstResponder() -> Bool {
        isRecording = false
        return super.resignFirstResponder()
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        if event.keyCode == UInt16(kVK_Escape) {
            isRecording = false
            return
        }

        let carbonModifiers = Self.carbonModifiers(from: event.modifierFlags)

        guard carbonModifiers != 0 else {
            NSSound.beep()
            return
        }

        let label = Self.keyLabel(for: event)
        let newConfig = HotkeyConfig(
            keyCode: UInt32(event.keyCode),
            carbonModifiers: carbonModifiers,
            label: label
        )

        config = newConfig
        isRecording = false
        onChange?(newConfig)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if isRecording {
            keyDown(with: event)
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var modifiers: UInt32 = 0
        if flags.contains(.command) { modifiers |= UInt32(cmdKey) }
        if flags.contains(.option) { modifiers |= UInt32(optionKey) }
        if flags.contains(.control) { modifiers |= UInt32(controlKey) }
        if flags.contains(.shift) { modifiers |= UInt32(shiftKey) }
        return modifiers
    }

    static func keyLabel(for event: NSEvent) -> String {
        if let special = specialKeyLabels[Int(event.keyCode)] {
            return special
        }

        if let chars = event.charactersIgnoringModifiers, !chars.isEmpty {
            return chars.uppercased()
        }

        return "Key \(event.keyCode)"
    }

    private static let specialKeyLabels: [Int: String] = [
        kVK_Space: "Space",
        kVK_Return: "Return",
        kVK_Tab: "Tab",
        kVK_Delete: "Delete",
        kVK_Escape: "Esc",
        kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4",
        kVK_F5: "F5", kVK_F6: "F6", kVK_F7: "F7", kVK_F8: "F8",
        kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12",
        kVK_LeftArrow: "←", kVK_RightArrow: "→",
        kVK_UpArrow: "↑", kVK_DownArrow: "↓"
    ]
}
