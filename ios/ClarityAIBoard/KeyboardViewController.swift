import KeyboardKit
import SwiftUI

class KeyboardViewController: KeyboardInputViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Sets up App Group data sync, services and observable state.
        setupKeyboardKit(for: .clarityAI) { _ in }
    }

    override func viewWillSetupKeyboardView() {
        setupKeyboardView { [weak self] controller in
            KeyboardView(
                services: controller.services,
                buttonContent: { $0.view },
                buttonView: { $0.view },
                collapsedView: { $0.view },
                emojiKeyboard: { $0.view },
                // Replace the default autocomplete toolbar with our Refine bar.
                toolbar: { _ in ClarityToolbar(controller: self) }
            )
        }
    }
}
