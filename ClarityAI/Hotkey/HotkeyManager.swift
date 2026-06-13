import AppKit
import Carbon

struct HotkeyConfig: Equatable {
    var keyCode: UInt32
    var carbonModifiers: UInt32
    var label: String

    static let `default` = HotkeyConfig(
        keyCode: UInt32(kVK_Space),
        carbonModifiers: UInt32(controlKey | optionKey),
        label: "Space"
    )

    var displayString: String {
        var result = ""
        if carbonModifiers & UInt32(controlKey) != 0 { result += "⌃" }
        if carbonModifiers & UInt32(optionKey) != 0 { result += "⌥" }
        if carbonModifiers & UInt32(shiftKey) != 0 { result += "⇧" }
        if carbonModifiers & UInt32(cmdKey) != 0 { result += "⌘" }
        result += label
        return result
    }

    var hasModifier: Bool {
        carbonModifiers & UInt32(controlKey | optionKey | shiftKey | cmdKey) != 0
    }
}

final class HotkeyManager {
    static let shared = HotkeyManager()

    var onHotkey: (() -> Void)?

    private(set) var config: HotkeyConfig

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    private enum Keys {
        static let keyCode = "hotkeyKeyCode"
        static let modifiers = "hotkeyModifiers"
        static let label = "hotkeyLabel"
    }

    private init() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: Keys.keyCode) != nil {
            config = HotkeyConfig(
                keyCode: UInt32(defaults.integer(forKey: Keys.keyCode)),
                carbonModifiers: UInt32(defaults.integer(forKey: Keys.modifiers)),
                label: defaults.string(forKey: Keys.label) ?? HotkeyConfig.default.label
            )
        } else {
            config = .default
        }
    }

    @discardableResult
    func update(_ newConfig: HotkeyConfig) -> Bool {
        config = newConfig

        let defaults = UserDefaults.standard
        defaults.set(Int(newConfig.keyCode), forKey: Keys.keyCode)
        defaults.set(Int(newConfig.carbonModifiers), forKey: Keys.modifiers)
        defaults.set(newConfig.label, forKey: Keys.label)

        return register()
    }

    @discardableResult
    func register() -> Bool {
        unregister()

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            hotkeyCallback,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )

        guard installStatus == noErr else { return false }

        let hotKeyID = EventHotKeyID(signature: OSType(0x434C5259), id: 1) // 'CLRY'

        let registerStatus = RegisterEventHotKey(
            config.keyCode,
            config.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if registerStatus != noErr {
            unregister()
            return false
        }

        return true
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }
}

private func hotkeyCallback(
    _ handler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let userData else {
        return OSStatus(eventNotHandledErr)
    }

    let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()

    DispatchQueue.main.async {
        manager.onHotkey?()
    }

    return noErr
}
