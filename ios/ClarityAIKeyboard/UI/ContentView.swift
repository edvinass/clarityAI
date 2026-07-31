import SwiftUI

struct ContentView: View {
    private let store = KeyboardSettingsStore.shared
    private let models = ["deepseek-v4-flash", "deepseek-v4-pro"]

    @State private var useStub: Bool
    @State private var apiToken: String
    @State private var model: String
    @State private var promptContext: String

    @State private var sample = "i thinks this sentance could of been written more clearer"
    @State private var refined = ""
    @State private var isRefining = false
    @State private var errorMessage: String?

    init() {
        let store = KeyboardSettingsStore.shared
        _useStub = State(initialValue: store.useStub)
        _apiToken = State(initialValue: store.apiToken)
        _model = State(initialValue: store.model)
        _promptContext = State(initialValue: store.promptContext)
    }

    var body: some View {
        NavigationStack {
            Form {
                setupSection
                engineSection
                contextSection
                tryItSection
            }
            .navigationTitle("ClarityAI Keyboard")
            .onChange(of: useStub) { _, value in store.useStub = value }
            .onChange(of: apiToken) { _, value in store.apiToken = value }
            .onChange(of: model) { _, value in store.model = value }
            .onChange(of: promptContext) { _, value in store.promptContext = value }
        }
    }

    private var setupSection: some View {
        Section("Setup") {
            Label("Open Settings ▸ General ▸ Keyboard ▸ Keyboards ▸ Add New Keyboard, then pick ClarityAI.", systemImage: "1.circle")
            Label("Tap ClarityAI in that list and enable \"Allow Full Access\" so it can reach the AI service.", systemImage: "2.circle")
            Label("In any text field, tap the globe to switch to the ClarityAI keyboard.", systemImage: "3.circle")
        }
        .font(.callout)
    }

    private var engineSection: some View {
        Section {
            Toggle("Use built-in stub (offline)", isOn: $useStub)
            SecureField("DeepSeek API token", text: $apiToken)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Picker("Model", selection: $model) {
                ForEach(models, id: \.self) { Text($0) }
            }
            .disabled(useStub)
        } header: {
            Text("Refinement engine")
        } footer: {
            Text(useStub
                 ? "Using the offline stub. Turn it off to refine with DeepSeek using the token below."
                 : "Using DeepSeek. Enable \"Allow Full Access\" for the keyboard so it can reach the API.")
        }
    }

    private var contextSection: some View {
        Section("Custom instructions (optional)") {
            TextField("e.g. keep it concise and professional", text: $promptContext, axis: .vertical)
                .lineLimit(2...5)
        }
    }

    private var tryItSection: some View {
        Section("Try it") {
            TextField("Sample text", text: $sample, axis: .vertical)
                .lineLimit(2...5)
            Button(action: runRefine) {
                HStack {
                    if isRefining { ProgressView() }
                    Text(isRefining ? "Refining…" : "Refine sample")
                }
            }
            .disabled(isRefining)

            if !refined.isEmpty {
                Text(refined)
                    .textSelection(.enabled)
                    .foregroundStyle(.primary)
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }

    private func runRefine() {
        errorMessage = nil
        refined = ""
        isRefining = true
        let service = store.makeService()
        let input = sample
        Task {
            do {
                let result = try await service.refine(input)
                await MainActor.run {
                    refined = result
                    isRefining = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    isRefining = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
