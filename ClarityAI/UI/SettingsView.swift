import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        Form {
            Section("Refinement") {
                Toggle("Preview before replacing", isOn: $appModel.previewBeforeReplace)
                Toggle("Use built-in stub (no API key)", isOn: $appModel.useStubRefinement)
                Toggle("Refine whole field when nothing is selected", isOn: $appModel.refineEntireFieldWhenNoSelection)

                Text("With this on, just click into a text field and trigger ClarityAI — no need to select text first. Select text to refine only that part.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("DeepSeek") {
                SecureField("API Token", text: $appModel.deepSeekToken)
                    .disabled(appModel.useStubRefinement)

                Picker("Model", selection: $appModel.deepSeekModel) {
                    Text("deepseek-v4-flash").tag("deepseek-v4-flash")
                    Text("deepseek-v4-pro").tag("deepseek-v4-pro")
                }
                .disabled(appModel.useStubRefinement)

                Text("When a token is set and stub mode is off, ClarityAI calls the DeepSeek API to refine text. Get a token at platform.deepseek.com.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Context") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Custom instructions")
                        .font(.subheadline)

                    TextEditor(text: $appModel.customContext)
                        .font(.body)
                        .frame(minHeight: 90)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.3))
                        )
                        .disabled(appModel.useStubRefinement)

                    Text("Optional guidance sent to the model with every refinement — e.g. tone, audience, language, or style. Example: \"Keep it formal and concise. Use British English.\"")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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
                    HotkeyRecorderView(
                        config: Binding(
                            get: { appModel.hotkeyConfig },
                            set: { appModel.updateHotkey($0) }
                        )
                    )
                    .frame(width: 220, height: 24)
                }

                Button("Reset to ⌃⌥Space") {
                    appModel.updateHotkey(.default)
                }

                if appModel.hotkeyRegistrationFailed {
                    Text("That shortcut couldn't be registered — it may be in use by macOS or another app. Try a different combination.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Text("Click the field, then press a shortcut (must include ⌃, ⌥, ⌘, or ⇧). You can also use the Services menu: select text, then choose Services → Refine with ClarityAI.")
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
        .frame(width: 480, height: 600)
    }
}
