import KeyboardKit

extension KeyboardApp {
    /// Shared app configuration. The `appGroupId` enables settings sync between
    /// the container app and this keyboard extension.
    static var clarityAI: KeyboardApp {
        .init(
            name: "ClarityAI",
            appGroupId: AppGroup.identifier
        )
    }
}
