import Foundation

/// Identifiers shared between the container app and the keyboard extension.
enum AppGroup {
    static let identifier = "group.com.clarityai.keyboard"

    /// App Group `UserDefaults` when the entitlement is provisioned; otherwise
    /// each process falls back to its own standard defaults.
    static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}
