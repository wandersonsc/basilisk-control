# Security policy

This is an early hardware-testing release. Security fixes target the latest source on `main`; no maintained older release branches are currently promised.

## Report a suspected vulnerability

Do not include vulnerability details, credentials, USB serial numbers, or personal data in a public issue.

Use the repository’s **Security → Advisories → Report a vulnerability** option when private reporting is enabled. If that option is unavailable, use a private contact method the maintainer publishes on their GitHub profile. If no private method is available, open an issue asking the maintainer to enable private security reporting, without exploit details. No response deadline is guaranteed.

A useful private report describes the affected commit/version, macOS version, prerequisites, impact, and minimal reproduction steps. Keep testing limited to devices and systems you are authorized to use.

Ordinary connection errors or unsupported firmware commands belong in a normal bug report with sensitive details removed.

## Relevant implementation boundaries

The app runs with the logged-in user’s permissions. It opens the matching USB HID control interface without seizing the mouse, validates report integrity, and writes settings only after an Apply action. It does not install a kernel extension, request administrator privileges, or make network requests. Presets are stored locally in UserDefaults; they are not encrypted or intended for secrets.

Build scripts and GitHub Actions are executable project code and should be reviewed before running. Locally built apps are ad-hoc signed, not Apple notarized. CI and packet tests do not replace physical device testing.
