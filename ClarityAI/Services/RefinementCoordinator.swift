import ApplicationServices
import Foundation

struct RefinementResult {
    let originalText: String
    let refinedText: String
    let focusedElement: AXUIElement?
    let scope: Scope
    let writeStrategy: WriteStrategy

    enum Scope {
        case selection
        case entireField
    }

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
            return "No text was found. Click into a text field (or select some text) and try again."
        }
    }
}

@MainActor
final class RefinementCoordinator {
    private let accessibilityService = AccessibilityTextService.shared
    private let pasteService = SyntheticPasteService.shared
    private var refinementService: TextRefining

    /// When true, refine the entire focused field if nothing is selected.
    var refineEntireFieldWhenNoSelection = true

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
        let (originalText, scope) = readText(focusedElement: focusedElement)

        guard let originalText else {
            throw RefinementCoordinatorError.noTextFound
        }

        let refinedText = try await refinementService.refine(originalText)
        let writeStrategy = preferredWriteStrategy(focusedElement: focusedElement, scope: scope)

        return RefinementResult(
            originalText: originalText,
            refinedText: refinedText,
            focusedElement: focusedElement,
            scope: scope,
            writeStrategy: writeStrategy
        )
    }

    func applyRefinement(_ result: RefinementResult) async throws {
        switch (result.scope, result.writeStrategy) {
        case (.selection, .accessibility):
            if !accessibilityService.setSelectedText(result.refinedText, on: result.focusedElement) {
                _ = pasteService.replaceSelection(with: result.refinedText)
            }

        case (.selection, .syntheticPaste):
            _ = pasteService.replaceSelection(with: result.refinedText)

        case (.entireField, .accessibility):
            if !accessibilityService.setFullText(result.refinedText, on: result.focusedElement) {
                _ = pasteService.replaceEntireField(with: result.refinedText)
            }

        case (.entireField, .syntheticPaste):
            _ = pasteService.replaceEntireField(with: result.refinedText)
        }
    }

    private func readText(focusedElement: AXUIElement?) -> (text: String?, scope: RefinementResult.Scope) {
        // Prefer an explicit selection if one exists.
        if let selected = accessibilityService.selectedText(from: focusedElement) {
            return (selected, .selection)
        }

        // No selection: optionally refine the entire field instead of requiring a highlight.
        if refineEntireFieldWhenNoSelection {
            if let full = accessibilityService.fullText(from: focusedElement) {
                return (full, .entireField)
            }

            if let captured = pasteService.captureEntireField() {
                return (captured, .entireField)
            }
        }

        // Last resort: synthetic copy of whatever selection might exist.
        if let pasted = pasteService.captureSelection() {
            return (pasted, .selection)
        }

        return (nil, .selection)
    }

    private func preferredWriteStrategy(
        focusedElement: AXUIElement?,
        scope: RefinementResult.Scope
    ) -> RefinementResult.WriteStrategy {
        let attribute = scope == .entireField
            ? (kAXValueAttribute as String)
            : (kAXSelectedTextAttribute as String)

        if accessibilityService.isAttributeSettable(attribute, on: focusedElement) {
            return .accessibility
        }

        return .syntheticPaste
    }
}
