import SwiftUI

@main
struct ClarityAIApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(AppModel.shared)
        }
    }
}
