import ApplicationServices
import Foundation

struct RefinementResult {
    let originalText: String
    let refinedText: String
    let focusedElement: AXUIElement?
    let writeStrategy: WriteStrategy

    enum WriteStrategy {
        case accessibility
        case syntheticPaste
    }
}

enum RefinementCoordinatorError: LocalizedError {
    case accessibilityPermissionRequired
    case noTextFound

    var errorDescription: String? {
        switch self {
        case .accessibilityPermissionRequired:
            return "Grant Accessibility access to ClarityAI in System Settings, then try again."
        case .noTextFound:
            return "No selected text was found. Highlight text in any app and try again."
        }
    }
}

@MainActor
final class RefinementCoordinator {
    private let accessibilityService = AccessibilityTextService.shared
    private let pasteService = SyntheticPasteService.shared
    private var refinementService: TextRefining

    init(refinementService: TextRefining) {
        self.refinementService = refinementService
    }

    func updateRefinementService(_ service: TextRefining) {
        refinementService = service
    }

    func refineText(_ text: String) async throws -> String {
        try await refinementService.refine(text)
    }

    func refineSelection() async throws -> RefinementResult {
        guard accessibilityService.requestPermission(prompt: false) else {
            throw RefinementCoordinatorError.accessibilityPermissionRequired
        }

        let focusedElement = accessibilityService.focusedElement()
        let originalText = readSelectedText(focusedElement: focusedElement)

        guard let originalText else {
            throw RefinementCoordinatorError.noTextFound
        }

        let refinedText = try await refinementService.refine(originalText)
        let writeStrategy = preferredWriteStrategy(focusedElement: focusedElement)

        return RefinementResult(
            originalText: originalText,
            refinedText: refinedText,
            focusedElement: focusedElement,
            writeStrategy: writeStrategy
        )
    }

    func applyRefinement(_ result: RefinementResult) async throws {
        switch result.writeStrategy {
        case .accessibility:
            let replaced = accessibilityService.setSelectedText(
                result.refinedText,
                on: result.focusedElement
            )

            if !replaced {
                _ = pasteService.replaceSelection(with: result.refinedText)
            }

        case .syntheticPaste:
            _ = pasteService.replaceSelection(with: result.refinedText)
        }
    }

    private func readSelectedText(focusedElement: AXUIElement?) -> String? {
        if let selected = accessibilityService.selectedText(from: focusedElement) {
            return selected
        }

        if let pasted = pasteService.captureSelection() {
            return pasted
        }

        return accessibilityService.fullText(from: focusedElement)
    }

    private func preferredWriteStrategy(focusedElement: AXUIElement?) -> RefinementResult.WriteStrategy {
        guard let focusedElement else {
            return .syntheticPaste
        }

        var isSettable = DarwinBoolean(false)
        let result = AXUIElementIsAttributeSettable(
            focusedElement,
            kAXSelectedTextAttribute as CFString,
            &isSettable
        )

        if result == .success, isSettable.boolValue {
            return .accessibility
        }

        return .syntheticPaste
    }
}
