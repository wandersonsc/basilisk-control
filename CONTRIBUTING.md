# Contributing

Bug reports, documentation improvements, and focused pull requests are welcome. Please follow the [code of conduct](CODE_OF_CONDUCT.md).

## Before making changes

- Check existing issues and pull requests for related work. For a substantial feature or a change to the USB protocol, open an issue to discuss the intended behavior first.
- Keep each pull request focused on one problem. Explain the current behavior and the result of the change.
- Do not include credentials, signing keys, serial numbers, personal logs, generated application bundles, or unrelated files.

## Develop locally

Clone the repository and create a branch:

```sh
git clone https://github.com/wandersonsc/basilisk-control.git
cd basilisk-control
git switch -c fix/describe-the-change
```

The macOS app requires macOS 13+ and Xcode 15+ command line tools with Swift 5.9+. Open `Package.swift` in Xcode or build with:

```sh
swift build --product BasiliskControl
```

Use `./"Build App.command"` on a Mac to build the complete locally signed application bundle. Linux can run the portable protocol tests but cannot build SwiftUI or verify macOS HID access.

## Validate the change

- Run `./test-protocol.sh` for protocol or transport changes. Add meaningful packet fixtures when introducing a new command or fixing an encoding/validation bug.
- Run `swift build -c release --product BasiliskControl` on a Mac for Swift or macOS transport changes. CI also runs this build.
- For hardware changes, use the README’s first hardware check. State whether you tested the cable, receiver, or both, and record any firmware/version limitations.
- For documentation-only changes, check commands and relative links; a hardware test is unnecessary.
- Describe any tests you could not run. A successful compile or packet test does not establish physical device compatibility.

Keep USB exchanges serialized, validate input before writing, preserve bounded retries, and surface partial failures. Device detection and periodic status refresh must remain read-only. Keep third-party code attribution and license notices intact.

## Submit a pull request

Use the pull request template. Describe the problem, resulting behavior, validation, and any hardware limitations. Update documentation and the Unreleased section of `CHANGELOG.md` when user-visible behavior changes. Follow the surrounding Swift and C style and avoid unrelated formatting changes.

Contributions are distributed under this repository’s MIT license. Only submit work you have permission to license that way.
