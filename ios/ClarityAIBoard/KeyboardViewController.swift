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
                KeyboardView(services: controller.services)
            }
        }
    }
}
