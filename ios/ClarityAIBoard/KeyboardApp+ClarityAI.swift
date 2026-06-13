import KeyboardKit

extension KeyboardApp {
    /// Shared app configuration for the keyboard extension.
    ///
    /// App Group is intentionally omitted here so the extension can launch on
    /// device without a registered App Group in the developer portal. Settings
    /// sync between the app and keyboard requires adding the App Group later.
    static var clarityAI: KeyboardApp {
        .init(
            name: "ClarityAI",
            locales: [.english]
        )
    }
}
