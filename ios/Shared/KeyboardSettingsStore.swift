import Foundation

/// Reads and writes ClarityAI settings to the shared App Group so the keyboard
/// extension can use values entered in the container app.
///
/// Note: the API token is stored in App Group `UserDefaults` for simplicity.
/// For production, move it to the Keychain with a shared access group.
final class KeyboardSettingsStore {
    static let shared = KeyboardSettingsStore()

    private let defaults: UserDefaults

    private enum Key {
        static let apiToken = "clarity.apiToken"
        static let model = "clarity.model"
        static let promptContext = "clarity.promptContext"
        static let useStub = "clarity.useStub"
    }

    init(suiteName: String = AppGroup.identifier) {
        defaults = UserDefaults(suiteName: suiteName) ?? .standard
    }

    var apiToken: String {
        get { defaults.string(forKey: Key.apiToken) ?? "" }
        set { defaults.set(newValue, forKey: Key.apiToken) }
    }

    var model: String {
        get { defaults.string(forKey: Key.model) ?? "deepseek-chat" }
        set { defaults.set(newValue, forKey: Key.model) }
    }

    var promptContext: String {
        get { defaults.string(forKey: Key.promptContext) ?? "" }
        set { defaults.set(newValue, forKey: Key.promptContext) }
    }

    /// Defaults to `true` so a freshly installed keyboard works offline.
    var useStub: Bool {
        get { defaults.object(forKey: Key.useStub) == nil ? true : defaults.bool(forKey: Key.useStub) }
        set { defaults.set(newValue, forKey: Key.useStub) }
    }

    /// Builds the appropriate refinement service for the current settings.
    func makeService() -> TextRefining {
        let hasToken = !apiToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if useStub || !hasToken {
            return StubTextRefinementService()
        }
        return DeepSeekTextRefinementService(apiToken: apiToken, model: model, context: promptContext)
    }
}
