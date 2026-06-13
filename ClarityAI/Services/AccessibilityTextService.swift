import ApplicationServices
import Foundation

final class AccessibilityTextService {
    static let shared = AccessibilityTextService()

    private init() {}

    func requestPermission(prompt: Bool) -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [key: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    func focusedElement() -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedValue
        )

        guard result == .success, let focusedValue else {
            return nil
        }

        return (focusedValue as! AXUIElement)
    }

    func selectedText(from element: AXUIElement? = nil) -> String? {
        guard let element = element ?? focusedElement() else { return nil }

        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            &value
        )

        guard result == .success, let text = value as? String, !text.isEmpty else {
            return nil
        }

        return text
    }

    func fullText(from element: AXUIElement? = nil) -> String? {
        guard let element = element ?? focusedElement() else { return nil }

        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            element,
            kAXValueAttribute as CFString,
            &value
        )

        guard result == .success, let text = value as? String, !text.isEmpty else {
            return nil
        }

        return text
    }

    @discardableResult
    func setSelectedText(_ text: String, on element: AXUIElement? = nil) -> Bool {
        guard let element = element ?? focusedElement() else { return false }

        let result = AXUIElementSetAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            text as CFTypeRef
        )

        return result == .success
    }

    @discardableResult
    func setFullText(_ text: String, on element: AXUIElement? = nil) -> Bool {
        guard let element = element ?? focusedElement() else { return false }

        let result = AXUIElementSetAttributeValue(
            element,
            kAXValueAttribute as CFString,
            text as CFTypeRef
        )

        return result == .success
    }

    func isAttributeSettable(_ attribute: String, on element: AXUIElement?) -> Bool {
        guard let element else { return false }

        var isSettable = DarwinBoolean(false)
        let result = AXUIElementIsAttributeSettable(element, attribute as CFString, &isSettable)
        return result == .success && isSettable.boolValue
    }
}
