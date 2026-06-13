import AppKit
import Combine
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    static let shared = AppModel()

    @Published var isRefining = false
    @Published var lastError: String?
    @Published var previewBeforeReplace: Bool {
        didSet { UserDefaults.standard.set(previewBeforeReplace, forKey: Keys.previewBeforeReplace) }
    }

    @Published var refineEntireFieldWhenNoSelection: Bool {
        didSet {
            UserDefaults.standard.set(refineEntireFieldWhenNoSelection, forKey: Keys.refineWholeField)
            refinementCoordinator.refineEntireFieldWhenNoSelection = refineEntireFieldWhenNoSelection
        }
    }

    @Published var deepSeekToken: String {
        didSet { UserDefaults.standard.set(deepSeekToken, forKey: Keys.deepSeekToken) }
    }

    @Published var deepSeekModel: String {
        didSet { UserDefaults.standard.set(deepSeekModel, forKey: Keys.deepSeekModel) }
    }

    @Published var useStubRefinement: Bool {
        didSet { UserDefaults.standard.set(useStubRefinement, forKey: Keys.useStubRefinement) }
    }

    @Published var hotkeyConfig: HotkeyConfig
    @Published var hotkeyRegistrationFailed = false

    let refinementCoordinator: RefinementCoordinator

    private init() {
        let defaults = UserDefaults.standard
        let storedPreview = defaults.object(forKey: Keys.previewBeforeReplace) as? Bool ?? false
        let storedWholeField = defaults.object(forKey: Keys.refineWholeField) as? Bool ?? true
        let storedToken = defaults.string(forKey: Keys.deepSeekToken) ?? ""
        let storedModel = defaults.string(forKey: Keys.deepSeekModel) ?? "deepseek-chat"
        let storedUseStub = defaults.object(forKey: Keys.useStubRefinement) as? Bool ?? true

        previewBeforeReplace = storedPreview
        refineEntireFieldWhenNoSelection = storedWholeField
        deepSeekToken = storedToken
        deepSeekModel = storedModel
        useStubRefinement = storedUseStub
        hotkeyConfig = HotkeyManager.shared.config

        refinementCoordinator = RefinementCoordinator(
            refinementService: AppModel.makeRefinementService(
                useStub: storedUseStub,
                token: storedToken,
                model: storedModel
            )
        )
        refinementCoordinator.refineEntireFieldWhenNoSelection = storedWholeField
    }

    func requestAccessibilityPermission() {
        _ = AccessibilityTextService.shared.requestPermission(prompt: true)
    }

    func updateHotkey(_ newConfig: HotkeyConfig) {
        hotkeyConfig = newConfig
        hotkeyRegistrationFailed = !HotkeyManager.shared.update(newConfig)
    }

    func refineCurrentSelection() async {
        guard !isRefining else { return }

        isRefining = true
        lastError = nil
        defer { isRefining = false }

        refinementCoordinator.updateRefinementService(
            AppModel.makeRefinementService(
                useStub: useStubRefinement,
                token: deepSeekToken,
                model: deepSeekModel
            )
        )

        do {
            let result = try await refinementCoordinator.refineSelection()

            if previewBeforeReplace {
                RefinementResultPanel.shared.present(result: result) { [weak self] in
                    Task { @MainActor in
                        await self?.applyRefinement(result)
                    }
                }
            } else {
                await applyRefinement(result)
            }
        } catch {
            lastError = error.localizedDescription
            presentError(error.localizedDescription)
        }
    }

    func applyRefinement(_ result: RefinementResult) async {
        do {
            try await refinementCoordinator.applyRefinement(result)
        } catch {
            lastError = error.localizedDescription
            presentError(error.localizedDescription)
        }
    }

    private func presentError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "ClarityAI"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private static func makeRefinementService(useStub: Bool, token: String, model: String) -> TextRefining {
        if useStub || token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return StubTextRefinementService()
        }
        let resolvedModel = model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "deepseek-chat" : model
        return DeepSeekTextRefinementService(apiToken: token, model: resolvedModel)
    }

    private enum Keys {
        static let previewBeforeReplace = "previewBeforeReplace"
        static let refineWholeField = "refineEntireFieldWhenNoSelection"
        static let deepSeekToken = "deepSeekAPIToken"
        static let deepSeekModel = "deepSeekModel"
        static let useStubRefinement = "useStubRefinement"
    }
}
