# Repository best practices

This guide distinguishes the conventions included in the source from optional GitHub settings a maintainer must configure. A checked-in policy file does not enable a GitHub account setting.

## Included in this repository

| File or check | Purpose |
| --- | --- |
| `README.md` | Features, setup, limitations, hardware checks, and project links |
| `LICENSE` and `NOTICE.md` | MIT terms and protocol attribution |
| `CONTRIBUTING.md` | Focused changes, development commands, and relevant validation |
| `CODE_OF_CONDUCT.md` | Respectful participation and handling concerns |
| `SECURITY.md` | Private reporting guidance and security boundaries |
| `CHANGELOG.md` | User-visible changes and honest verification status |
| Issue and PR templates | Reproduction details, test evidence, and hardware context |
| `.gitignore` and `.gitattributes` | Keep generated files, local settings, and credentials out of commits; preserve text line endings |
| GitHub Actions | Linux packet tests and native macOS compilation with timeouts, read-only token permissions, and pinned checkout action |
| Dependabot configuration | Weekly proposals to update GitHub Actions dependencies |

## Suggested GitHub settings

These settings are recommendations, not claims that they have been enabled:

1. Protect `main` with a branch ruleset once the repository is initialized. Require pull requests and successful **Protocol tests (Linux)** and **Native macOS build** checks before merging. Require review when a second maintainer is available; avoid creating a rule that prevents a sole maintainer from merging work.
2. Block force pushes and branch deletion. Keep any administrator bypass explicit and limited.
3. Enable private vulnerability reporting, dependency alerts, and secret scanning/push protection where supported by the repository’s visibility and plan. Check that the reporting link is available before advertising it as enabled.
4. Set GitHub Actions workflow permissions to read-only by default. Require approval before workflows from untrusted forks run. Do not expose credentials to fork pull requests or use `pull_request_target` to execute untrusted source.
5. Keep the repository description and topics accurate: macOS, SwiftUI, Razer, Basilisk Ultimate, USB HID. Publish build status as a status indicator, not a claim of hardware compatibility.
6. Delete merged feature branches when practical and use clear commit messages. Add code owners if more maintainers take responsibility for specific paths.

## Review and release workflow

- Use a feature branch and a focused pull request after the initial import. Review device writes, input validation, retry limits, and error handling when USB behavior changes.
- Run relevant checks, then test the actual mouse over the cable and receiver before claiming support for a release. State untested firmware or connection modes explicitly.
- Review files for credentials and personal data before pushing. If a secret is committed, revoke or rotate it; deleting the file alone is insufficient.
- Keep Unreleased notes current. Tag a release only after its version, changelog, build, and hardware verification agree. Do not tag the initial source as a hardware-verified release.
- Publish installation requirements, known limitations, source, checksums, and signing/notarization status with any distributable app. Do not label an ad-hoc signed app as notarized. Keep signing credentials in managed secrets rather than the repository.
- Review dependency update PRs and pinned action changes before merging. Check their source and test results.

## License and attribution

Keep the existing MIT license and source notices consistent. Review compatibility before importing third-party code, and update `NOTICE.md` where appropriate. Do not include proprietary Razer firmware, logos, or undocumented claims of endorsement.
