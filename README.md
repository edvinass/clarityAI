# ClarityAI

Refine selected text in place on macOS — no copy/paste workflow required.

ClarityAI is a menu bar app that reads your current text selection from any app, sends it to an AI refinement service, and writes the improved text back in place.

## How it works

1. **Select text** in Mail, Notes, Slack, Chrome, or any editable field.
2. **Trigger refinement** using one of:
   - Global hotkey: **⌥ Space** (Option + Space)
   - Menu bar: **Refine Selection**
   - macOS Services: **Services → Refine with ClarityAI**
3. ClarityAI replaces the selection with refined text.

### In-place replacement strategy

ClarityAI uses two macOS APIs, in order:

1. **Accessibility API** (`AXUIElement`) — reads `kAXSelectedTextAttribute` and writes back via `kAXSelectedTextAttribute` when the focused app supports it.
2. **Synthetic paste fallback** — saves your clipboard, sends ⌘C to capture selection, refines text, sends ⌘V to paste, then restores the clipboard. This works in Electron apps, browsers, and other apps with limited Accessibility write support.

## Requirements

- macOS 14.0+
- Xcode 15+
- **Accessibility permission** (required for reading/replacing text in other apps)

## Setup

1. Open `ClarityAI.xcodeproj` in Xcode.
2. Build and run (**⌘R**).
3. When prompted, grant **Accessibility** access in **System Settings → Privacy & Security → Accessibility**.
4. Open **Settings** from the menu bar:
   - Leave **Use built-in stub** on for offline testing (capitalizes sentences).
   - Or turn stub off and enter an **OpenAI API key** for real AI refinement (`gpt-4o-mini`).
   - Enable **Preview before replacing** to review changes before they are applied.

## Project structure

```
ClarityAI/
├── ClarityAIApp.swift          # App entry point
├── AppDelegate.swift           # Menu bar, hotkey, NSServices
├── AppModel.swift              # App state and orchestration
├── Services/
│   ├── AccessibilityTextService.swift
│   ├── SyntheticPasteService.swift
│   ├── TextRefinementService.swift
│   └── RefinementCoordinator.swift
├── Hotkey/
│   └── HotkeyManager.swift     # ⌥ Space global hotkey (Carbon)
└── UI/
    ├── RefinementResultPanel.swift
    └── SettingsView.swift
```

## Distribution note

This app is **not sandboxed** because Accessibility and synthetic keyboard events require capabilities unavailable in the Mac App Store sandbox. Distribute via Developer ID signing and notarization outside the App Store.

## License

MIT
