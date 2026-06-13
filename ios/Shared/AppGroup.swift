import Foundation

/// Identifiers shared between the container app and the keyboard extension.
///
/// Both targets must declare this App Group in their entitlements so the
/// keyboard can read settings (API token, prompt context) saved by the app.
enum AppGroup {
    static let identifier = "group.com.clarityai.keyboard"
}
