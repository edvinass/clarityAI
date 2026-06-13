# ClarityAI Keyboard (iOS)

An iOS custom keyboard, built with [KeyboardKit](https://github.com/KeyboardKit/KeyboardKit),
that refines the text around your cursor in any app. It reuses the same DeepSeek /
offline-stub refinement logic as the macOS ClarityAI app, but is a **separate,
self-contained iOS project** (no shared code with the macOS target).

## Layout

```
ios/
├── project.yml                 # XcodeGen spec (source of truth for the project)
├── Shared/                     # Compiled into BOTH targets
│   ├── AppGroup.swift          # App Group identifier
│   ├── KeyboardSettingsStore.swift  # Reads/writes settings via App Group
│   └── TextRefinementService.swift  # Stub + DeepSeek services
├── ClarityAIKeyboard/          # Container app (settings + onboarding)
│   ├── ClarityAIKeyboardApp.swift
│   ├── UI/ContentView.swift
│   ├── Info.plist
│   └── ClarityAIKeyboard.entitlements
└── ClarityAIBoard/             # The keyboard extension
    ├── KeyboardViewController.swift   # KeyboardKit setup
    ├── KeyboardApp+ClarityAI.swift    # Shared KeyboardApp config
    ├── ClarityToolbar.swift           # "Refine" button toolbar
    ├── Info.plist                     # RequestsOpenAccess = YES
    └── ClarityAIBoard.entitlements
```

## How it works

- The **container app** lets you choose the engine (offline stub or DeepSeek),
  enter your API token + custom instructions, and try a sample refinement.
  Settings are written to an **App Group** (`group.com.clarityai.keyboard`).
- The **keyboard extension** reads those settings from the same App Group and
  shows a **Refine** button above the keys. Tapping it sends the text around the
  cursor to the refinement service and replaces it with the improved version.

## Requirements

- Xcode 15+, iOS 17.0+ target
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`) — only
  needed to (re)generate the `.xcodeproj`
- A DeepSeek API token (optional; the offline stub works without one)

## Generate & build

```bash
cd ios
xcodegen generate                 # creates ClarityAIKeyboard.xcodeproj
open ClarityAIKeyboard.xcodeproj  # then set your signing team and run
```

The project file is generated, so edit `project.yml` (not the `.xcodeproj`) and
re-run `xcodegen generate` when changing targets/settings.

## Enable the keyboard on device

1. Run the **ClarityAIKeyboard** app once and configure your engine/token.
2. **Settings ▸ General ▸ Keyboard ▸ Keyboards ▸ Add New Keyboard… ▸ ClarityAI**.
3. Tap **ClarityAI** in that list and enable **Allow Full Access**.
   - This is **required** for the DeepSeek (network) engine. Without it, iOS
     blocks all network access from the keyboard and ClarityAI falls back to a
     clear error; the offline stub still works.
4. In any text field, tap the 🌐 globe key to switch to the ClarityAI keyboard,
   then tap **Rewrite**.

### If you see the stock iOS keyboard (mic icon, no Rewrite bar)

iOS falls back to the system keyboard when the extension **crashes on launch**.
Common causes:

1. **Signing** — in Xcode, set your **Development Team** on **both** targets
   (`ClarityAIKeyboard` and `ClarityAIBoard`), then delete the app from the
   device and Run again.
2. **Stale extension** — delete the app, restart the phone, reinstall, and
   re-add the keyboard in Settings.
3. **Crash logs** — Xcode → Window → Devices and Simulators → your iPhone →
   Open Console, then switch to the ClarityAI keyboard and look for
   `ClarityAIBoard` errors.

When the extension loads correctly, the keyboard looks like KeyboardKit (no
system dictation mic) and shows a **Rewrite** bar above the keys.

## Important constraints (iOS keyboard extensions)

- **No network without Full Access.** `RequestsOpenAccess` is set to `YES` in the
  extension's `Info.plist`, but the user must still toggle it on in Settings.
- **Tight memory budget (~60–70 MB).** That is why refinement calls a remote API
  rather than running an on-device model.
- **Cursor-context only.** `documentContextBeforeInput`/`AfterInput` expose only
  the text near the cursor (and may be truncated for long documents), so the
  keyboard refines nearby text rather than an entire field.

## Notes / next steps

- App Group sync is **disabled by default** so the extension can launch without
  registering `group.com.clarityai.keyboard` in the Apple Developer portal. The
  app and keyboard each use their own defaults until you add the App Group
  capability to both targets and re-enable `appGroupId` in `KeyboardApp+ClarityAI.swift`.
- The API token is stored in `UserDefaults`. For production, move it to the
  Keychain with a shared access group.
- KeyboardKit's autocomplete / AI next-word prediction features require
  **KeyboardKit Pro** (a `licenseKey` on the `KeyboardApp`). The current setup
  uses the free tier with a custom toolbar.
