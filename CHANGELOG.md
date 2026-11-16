# Changelog

Document user-visible changes here. Entries under Unreleased are not a published release or a claim of hardware verification.

## Unreleased

### Added

- Initial native macOS app source for Basilisk Ultimate wired and receiver connections.
- DPI and polling controls with readback, lighting commands, battery/charging readings, local presets, and menu bar controls.
- Portable packet tests and a local application bundle build script.
- Contributing and security guidance, a code of conduct, issue and PR templates, repository setup guidance, and CI checks.
- Universal Apple Silicon/Intel app packaging with local signing, a SHA-256 checksum, a CI launch check, and downloadable build artifacts.

### Fixed

- Renamed the canvas color to avoid a name collision with SwiftUI’s `background` method during compilation.

### Verification

- Portable packet tests passed on Linux during initial preparation.
- Native macOS build status is available in GitHub Actions once a run completes. Physical mouse behavior still requires hardware testing.
