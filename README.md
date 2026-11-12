# Snaplet

A native macOS menu bar app for saving and restoring named window layouts. Requires macOS 14 or newer and Xcode's Swift toolchain.

## Build and run

One-time setup: create a **Self Signed Root / Code Signing** identity named **Snaplet** using Keychain Access → Certificate Assistant → Create a Certificate. Store it in your login Keychain. Use only the code-signing purpose and leave certificate-authority capability disabled. The configured certificate-pinned signature works without adding a trust rule. Then bind this project to its public certificate identity:

```sh
python3 scripts/configure-local-signing.py
```

Build and run:

```sh
./scripts/build-app.sh
open ".build/Snaplet.app"
```

Look for the overlapping rectangles icon in the menu bar near the clock. The app runs without a Dock icon. It opens the layout manager when Accessibility access is missing; otherwise it starts in the menu bar. Reopening the app also brings up the manager.

Click the menu bar icon to open the window palette. Its tiles fill, halve, quarter, center, move between displays, toggle full screen (where supported), or revert the selected window. Hover a tile to see its label.

With Accessibility access enabled, hovering a standard window’s green button also opens a palette for that window. Move into the palette to choose an action, or move away to dismiss it. **Manage Layouts…** includes a toggle and delay setting for this behavior.

Choose **Manage Layouts…** to open the layout manager. Arrange your windows, enter a name such as **Laptop** or **Development**, then save. To replace a preset, arrange your windows and click **Update** beside that preset in the manager. This keeps its name and replaces its saved windows and positions. If no eligible windows can be captured, the existing preset is kept. Restore a saved layout directly from the menu bar. Closing the layout manager leaves the app running; use **Quit Snaplet** from its menu to exit.

Use **Accessibility Settings** in the layout manager to grant Snaplet access to move and resize other apps' windows. Saved layouts are stored in `~/Library/Application Support/Snaplet/layouts.json`.

## Current limits

Apps must already be open. Layouts save absolute window positions; adapting them to changed display configurations and reliably distinguishing multiple windows with changing titles are future improvements. Automatic switching when displays change is not implemented.

## Development status

Snaplet is under active development and uses supported Apple APIs.

The app builds successfully, and all nine geometry and preset-persistence tests pass. Accessibility access was granted and the enabled state was verified in the app. Live window-control and hover interaction still require verification. Local builds use **Snaplet**. Its private key stays in your login Keychain. The ignored `.local/signing.json` stores only public certificate identification and the Keychain path; keep it across clean builds.

The app's signing requirement pins its bundle identifier and this specific certificate. Switching identity requires approving window-control access once. Two different signed app versions were verified to have the same signing requirement and to satisfy each other’s requirement. Permission retention was verified with the Snaplet certificate: after replacing the Device Control and Data Access entry, an icon-bearing rebuild was relaunched and still reported Accessibility access enabled. A missing identity stops the build with an error.

`SNAPLET_SIGNING_IDENTITY` is an explicit override. Setting it to `-` creates a temporary signature that can require renewed permission.

Palette limitations: only the green-button trigger is implemented so far; custom palette editing, alternate modifiers, and cross-display gestures remain pending. macOS can show its own green-button menu as well; we do not use private hooks to suppress it. Full-screen actions work only when the target app publishes the supported Accessibility full-screen button. Palette placement actions can be constrained by the target app's minimum size.

Run the geometry checks with `swift test`. These checks do not move any of your windows.

## Local signing identity

The project identity is **Snaplet**, self-signed with no organization or Apple Developer team. It was created in the login Keychain using Certificate Assistant, with only digital-signature/code-signing usage and certificate-authority capability disabled. It expires on **12 November 2027**. The private key was not exported. No additional user or system trust rule was added.

The local build scripts pin the app identity to this certificate and `local.snaplet.app`. The certificate's public SHA-1 identifier is stored in `.local/signing.json`; that file is ignored by Git and is independent of `.build/`.

## Naming and existing data

Snaplet uses the existing `local.snaplet.app` bundle identifier and a local signing certificate named **Snaplet**. When switching certificates, remove the previous Device Control and Data Access entry and add the newly signed app once; subsequent builds reuse the new certificate. Its preset data stays in `~/Library/Application Support/Snaplet/layouts.json`. The executable, app bundle, window titles, and menu bar label now use **Snaplet**.

## App icon

The icon source is `Packaging/AppIcon.png`, and the macOS icon bundle is `Packaging/Snaplet.icns`. `scripts/build-app.sh` regenerates the icon bundle when needed and includes it before signing the app. To regenerate only the icon bundle, run `./scripts/build-icon.sh`. The generation prompts are recorded in `Packaging/AppIcon.prompt.md`.
