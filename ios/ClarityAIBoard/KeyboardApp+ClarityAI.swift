import KeyboardKit

extension KeyboardApp {
    /// Shared app configuration. `appGroupId` syncs settings between the
    /// container app and this keyboard extension via App Group UserDefaults.
    static var clarityAI: KeyboardApp {
        .init(
            name: "ClarityAI",
            appGroupId: AppGroup.identifier,
            locales: [.english]
        )
    }
}
