import KeyboardKit
import SwiftUI

/// Entry point for the ClarityAI keyboard extension.
@objc(KeyboardViewController)
class KeyboardViewController: KeyboardInputViewController {

    override func viewWillSetupKeyboardKit() {
        super.viewWillSetupKeyboardKit()
        setupKeyboardKit(for: .clarityAI) { _ in }
    }

    override func viewWillSetupKeyboardView() {
        setupKeyboardView { [weak self] controller in
            VStack(spacing: 0) {
                ClarityToolbar(controller: self)
                KeyboardView(
                    services: controller.services,
                    buttonContent: { $0.view },
                    buttonView: { $0.view },
                    collapsedView: { $0.view },
                    emojiKeyboard: { $0.view },
                    // Collapse the built-in autocomplete toolbar so there is no
                    // empty strip between our bar and the keys.
                    toolbar: { _ in EmptyView() }
                )
            }
        }
    }
}
