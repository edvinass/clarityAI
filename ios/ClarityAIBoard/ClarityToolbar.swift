import KeyboardKit
import SwiftUI
import UIKit

/// Toolbar shown above the keys (in the slot iOS normally uses for autocomplete).
///
/// It keeps a native, subtle look: a trailing "Rewrite" pill with a wand icon,
/// plus inline status/progress. Tapping it refines the text around the cursor.
struct ClarityToolbar: View {
    weak var controller: KeyboardInputViewController?

    @State private var phase: Phase = .idle

    private let store = KeyboardSettingsStore.shared

    private enum Phase: Equatable {
        case idle
        case working
        case message(String)
    }

    var body: some View {
        HStack(spacing: 8) {
            statusView
            Spacer(minLength: 0)
            rewriteButton
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(Color.accentColor.opacity(0.12))
    }

    @ViewBuilder
    private var statusView: some View {
        switch phase {
        case .idle:
            Text("ClarityAI")
                .font(.footnote)
                .foregroundStyle(.secondary)
        case .working:
            HStack(spacing: 6) {
                ProgressView()
                Text("Rewriting…")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        case .message(let text):
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }

    private var rewriteButton: some View {
        Button(action: rewrite) {
            HStack(spacing: 6) {
                Image(systemName: "wand.and.stars")
                Text("Rewrite").fontWeight(.semibold)
            }
            .font(.subheadline)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundStyle(.white)
            .background(Color.accentColor, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(phase == .working)
        .opacity(phase == .working ? 0.5 : 1)
    }

    private func rewrite() {
        guard let proxy = controller?.textDocumentProxy else { return }

        let before = proxy.documentContextBeforeInput ?? ""
        let after = proxy.documentContextAfterInput ?? ""
        let original = before + after

        guard !original.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            flash("Nothing to rewrite")
            return
        }

        phase = .working
        let service = store.makeService()

        Task {
            do {
                let result = try await service.refine(original)
                await MainActor.run {
                    replace(before: before, after: after, with: result, in: proxy)
                    flash("Done")
                }
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? "Couldn't rewrite"
                await MainActor.run { flash(message) }
            }
        }
    }

    /// Shows a transient status message, then returns to idle.
    private func flash(_ text: String) {
        phase = .message(text)
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run {
                if case .message = phase { phase = .idle }
            }
        }
    }

    /// Replaces the available text context around the cursor with `text`.
    ///
    /// Note: `documentContextBeforeInput`/`AfterInput` may be truncated by the
    /// host app for long documents, so this rewrites the nearby context, not
    /// necessarily the entire field.
    private func replace(before: String, after: String, with text: String, in proxy: UITextDocumentProxy) {
        if !after.isEmpty {
            proxy.adjustTextPosition(byCharacterOffset: after.count)
        }
        let deleteCount = before.count + after.count
        for _ in 0..<deleteCount {
            proxy.deleteBackward()
        }
        proxy.insertText(text)
    }
}
