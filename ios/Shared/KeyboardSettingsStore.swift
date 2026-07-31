import Foundation

/// Reads and writes ClarityAI settings so the keyboard extension can use values
/// entered in the container app (when App Group is provisioned).
final class KeyboardSettingsStore {
    static let shared = KeyboardSettingsStore()

    private let defaults: UserDefaults

    private enum Key {
        static let apiToken = "clarity.apiToken"
        static let model = "clarity.model"
        static let promptContext = "clarity.promptContext"
        static let useStub = "clarity.useStub"
    }

    init(defaults: UserDefaults = AppGroup.defaults) {
        self.defaults = defaults
    }

    var apiToken: String {
        get { defaults.string(forKey: Key.apiToken) ?? "" }
        set { defaults.set(newValue, forKey: Key.apiToken) }
    }

    var model: String {
        get {
            let stored = defaults.string(forKey: Key.model) ?? "deepseek-v4-flash"
            switch stored {
            case "deepseek-chat":
                defaults.set("deepseek-v4-flash", forKey: Key.model)
                return "deepseek-v4-flash"
            case "deepseek-reasoner":
                defaults.set("deepseek-v4-pro", forKey: Key.model)
                return "deepseek-v4-pro"
            default:
                return stored
            }
        }
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

    func makeService() -> TextRefining {
        let hasToken = !apiToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if useStub || !hasToken {
            return StubTextRefinementService()
        }
        return DeepSeekTextRefinementService(apiToken: apiToken, model: model, context: promptContext)
    }
}
