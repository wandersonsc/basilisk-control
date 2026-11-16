# Basilisk Control for macOS

A native SwiftUI app for the **Razer Basilisk Ultimate**, with direct USB HID controls and a menu bar companion. Works with its USB cable (`1532:0086`) or original 2.4 GHz receiver (`1532:0088`). No third-party runtime dependencies or kernel extensions.

[Build checks](https://github.com/wandersonsc/basilisk-control/actions) · [Contributing](CONTRIBUTING.md) · [Security](SECURITY.md) · [Repository practices](docs/REPOSITORY_BEST_PRACTICES.md) · [MIT](LICENSE)

**Delivery status:** complete source project, not a precompiled or notarized application. Packet tests were run on Linux. This environment cannot compile SwiftUI or access your mouse, so the macOS build, HID transport, and physical device behavior remain unverified. Treat version 0.1 as an initial hardware-testing release.

## Build and open on your Mac

Requires **macOS 13 or newer**, and **Xcode 15+ command line tools with Swift 5.9+**. Builds locally for your Mac’s architecture, including Apple Silicon or Intel.

1. Extract this folder somewhere writable, such as Documents.
2. If Apple’s developer tools are missing, open Terminal, run `xcode-select --install`, and finish the installation. An older macOS installation may require a compatible Xcode 15+ from Apple’s developer downloads.
3. Double-click **Build App.command**. It runs the packet tests, compiles the app, creates an application bundle, signs it locally, and opens it. If Finder cannot execute the script, use Terminal:

   ```sh
   cd "/path/to/BasiliskControl"
   chmod +x "Build App.command" test-protocol.sh
   ./"Build App.command"
   ```

4. The result is **dist/Basilisk Control.app**. Move it to Applications if desired.
5. Connect the mouse or receiver, turn it on, and click **Refresh**. No settings are written automatically.

The app is locally ad-hoc signed, not Apple notarized. If macOS blocks a file you downloaded, review it and use **System Settings → Privacy & Security → Open Anyway** if you trust it. Do not disable Gatekeeper systemwide. If macOS denies HID access, enable **Basilisk Control** in **Privacy & Security → Input Monitoring**, then quit and reopen it. The Connection screen includes a shortcut.

You can also open `Package.swift` in Xcode to inspect and build the source. Use the build script to create the installable bundle with its icon and identity.

## Controls

- **Performance:** hardware DPI from 100 to 20,000 in increments of 50, linked or separate X/Y axes, and polling at 125, 500, or 1000 Hz. Apply buttons write settings and verify them by reading back.
- **Lighting:** static color, spectrum cycling, or off; brightness; wheel, logo, left side, right side, or all zones. Values shown are drafts, not readings of existing effects. Commands require a valid device acknowledgment; the actual effect still needs verification on your firmware.
- **Presets:** save DPI and polling combinations locally on this Mac; apply from the app or menu bar. Names are case insensitive; saving an existing name replaces it. Up to 30 presets.
- **Status:** live battery percentage, charging status, DPI, polling, connection, and refresh timestamp. Polls every 30 seconds while the app runs, including when its window is closed. ⌘R refreshes manually.

Changing a draft, saving a preset, launching, or reconnecting never writes device settings. Apply commands are the only write path. Some commands request variable storage, following the documented protocol, so changes may survive closing the app or a power cycle depending on firmware. The app does not edit the hardware profile slots or automatically reapply presets.

**Not included:** button remapping, macros, clutch assignments, hardware DPI stages, per-application switching, onboard profile editing, and individual addressing of all 14 LEDs. The scroll resistance dial is mechanical. This utility does not replace every Synapse feature.

## First hardware check

1. Start with the USB data cable. Confirm the connection, battery, current DPI, and polling readings. Unknown values display `—`; a partial read failure is shown explicitly.
2. Note your original DPI. Apply a different DPI, confirm cursor behavior and the refreshed value, then restore it.
3. Apply a polling rate and confirm the readback. Restore your preferred rate.
4. Apply a static color to the logo first, then try the other zones, spectrum, brightness, and off.
5. Repeat using the wireless receiver. Move the mouse if it is asleep.

Use one Basilisk Ultimate at a time. If both its cable and receiver appear, wired takes priority. Close Synapse, MacRazer, OpenSnek, or any other mouse utility while testing so they do not consume or overwrite replies. A failed multi-command operation can leave earlier changes applied; the app refreshes readings even after a failure. Lighting effects are acknowledged but not read back, so inspect the actual mouse.

## Implementation and verification

`Sources/BasiliskHID/Protocol.c` is a portable 90-byte report encoder/validator. It checks input bounds, XOR checksum, response size, transaction and command identity, firmware result, and busy/stale replies. `Transport.c` enumerates only vendor `0x1532`, product `0x0086` or `0x0088`, with a control feature report of at least 90 bytes. It opens nonexclusively and does not intercept mouse events. Commands use report ID zero and a 35 ms response delay; busy/stale responses get a bounded read retry without blindly resending writes.

`DeviceService` serializes calls in a Swift actor so USB operations do not block the UI. Readings stay distinct from editable drafts. Presets use local UserDefaults. The app makes no network requests.

Run packet tests on macOS or Linux:

```sh
./test-protocol.sh
```

Tests cover fixed wire fixtures, all supported DPI increments, polling mappings, brightness limits, malformed replies, checksum corruption, stale/busy replies, and firmware error statuses. The included GitHub Actions workflow compiles the native app on a macOS runner when used in a repository; that workflow has not been run as part of this delivery. Physical tests above are still necessary.

## Protocol references and license

The packet layout and Basilisk-specific constants were checked against [OpenRazer](https://github.com/openrazer/openrazer), particularly `driver/razercommon.h`, `driver/razerchromacommon.c`, and the Basilisk Ultimate cases in `driver/razermouse_driver.c`. The macOS HID approach was cross-checked against the [MacRazer documentation and implementation](https://github.com/SorcRR/MacRazer). This is an independent project and is not affiliated with Razer. Razer and Basilisk are their owners’ trademarks.

Source licensed under **MIT**; see [LICENSE](LICENSE) and [NOTICE.md](NOTICE.md).

## Help and contributions

Use [GitHub Issues](https://github.com/wandersonsc/basilisk-control/issues) for reproducible bugs and feature requests. Include your macOS version, Mac architecture, mouse firmware if known, connection type, and reproduction steps. Remove serial numbers and other personal data from logs. Report suspected vulnerabilities according to [SECURITY.md](SECURITY.md).

See [CONTRIBUTING.md](CONTRIBUTING.md) for development and validation steps, [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for community expectations, and [CHANGELOG.md](CHANGELOG.md) for changes. Maintainer setup and release guidance are in [Repository best practices](docs/REPOSITORY_BEST_PRACTICES.md).
