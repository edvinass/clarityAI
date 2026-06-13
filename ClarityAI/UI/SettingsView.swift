import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        Form {
            Section("Refinement") {
                Toggle("Preview before replacing", isOn: $appModel.previewBeforeReplace)
                Toggle("Use built-in stub (no API key)", isOn: $appModel.useStubRefinement)
            }

            Section("OpenAI") {
                SecureField("API Key", text: $appModel.apiKey)
                    .disabled(appModel.useStubRefinement)

                Text("When a key is set and stub mode is off, ClarityAI uses gpt-4o-mini to refine text.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Permissions") {
                Text("ClarityAI needs Accessibility access to read and replace selected text in other apps.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Open Accessibility Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }

            Section("Shortcuts") {
                LabeledContent("Global hotkey") {
                    Text("⌥ Space")
                }

                Text("You can also use the Services menu: select text, then choose Services → Refine with ClarityAI.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let lastError = appModel.lastError {
                Section("Last Error") {
                    Text(lastError)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 420)
        .padding()
    }
}
