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

    @Published var deepSeekToken: String {
        didSet { UserDefaults.standard.set(deepSeekToken, forKey: Keys.deepSeekToken) }
    }

    @Published var deepSeekModel: String {
        didSet { UserDefaults.standard.set(deepSeekModel, forKey: Keys.deepSeekModel) }
    }

    @Published var useStubRefinement: Bool {
        didSet { UserDefaults.standard.set(useStubRefinement, forKey: Keys.useStubRefinement) }
    }

    let refinementCoordinator: RefinementCoordinator

    private init() {
        let defaults = UserDefaults.standard
        let storedPreview = defaults.object(forKey: Keys.previewBeforeReplace) as? Bool ?? false
        let storedToken = defaults.string(forKey: Keys.deepSeekToken) ?? ""
        let storedModel = defaults.string(forKey: Keys.deepSeekModel) ?? "deepseek-chat"
        let storedUseStub = defaults.object(forKey: Keys.useStubRefinement) as? Bool ?? true

        previewBeforeReplace = storedPreview
        deepSeekToken = storedToken
        deepSeekModel = storedModel
        useStubRefinement = storedUseStub

        refinementCoordinator = RefinementCoordinator(
            refinementService: AppModel.makeRefinementService(
                useStub: storedUseStub,
                token: storedToken,
                model: storedModel
            )
        )
    }

    func requestAccessibilityPermission() {
        _ = AccessibilityTextService.shared.requestPermission(prompt: true)
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
        static let deepSeekToken = "deepSeekAPIToken"
        static let deepSeekModel = "deepSeekModel"
        static let useStubRefinement = "useStubRefinement"
    }
}
