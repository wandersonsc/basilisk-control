# Notices

Basilisk Control, version 0.1.0. Original application and transport code created for this project in 2026, distributed under the MIT License.

Protocol references:

- OpenRazer: https://github.com/openrazer/openrazer (GPL-2.0-or-later). Protocol documentation and device-specific constants in `driver/razercommon.h`, `driver/razerchromacommon.c`, and `driver/razermouse_driver.c`. OpenRazer contributor credits include Tim Theede and Terri Cain; see upstream for complete authorship.
- MacRazer: https://github.com/SorcRR/MacRazer (GPL-2.0-or-later). Reviewed as a reference for the macOS IOHID feature-report approach; its application code is not bundled.

The project implements the documented wire format in its own small C encoder and native SwiftUI application. The icon is an original programmatically drawn mouse design. No Razer artwork is included. Product names identify device compatibility and do not imply endorsement.

The MIT License applies to this project’s original code. The references above retain their upstream licenses; no upstream application or driver source is bundled. Protocol identifiers and packet layouts were used as interoperability information.
