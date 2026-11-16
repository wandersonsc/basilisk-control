// SPDX-License-Identifier: MIT
import SwiftUI

private let accent = Color(red: 0.42, green: 0.94, blue: 0.65)
private let background = Color(red: 0.055, green: 0.065, blue: 0.075)

enum Page: String, CaseIterable {
    case performance = "Performance", lighting = "Lighting", presets = "Presets", connection = "Connection"
    var symbol: String {
        switch self {
        case .performance: return "speedometer"
        case .lighting: return "lightbulb"
        case .presets: return "slider.horizontal.3"
        case .connection: return "cable.connector"
        }
    }
    var subtitle: String {
        switch self {
        case .performance: return "Find your perfect feel."
        case .lighting: return "Make it your own."
        case .presets: return "Your settings, one click away."
        case .connection: return "A direct connection to your mouse."
        }
    }
}

@MainActor
struct ContentView: View {
    @ObservedObject var model: AppModel
    @State private var page = Page.performance

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider().overlay(Color.white.opacity(0.04))
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    deviceCard
                    if model.hasScanned || model.busy { statusMessage }
                    switch page {
                    case .performance: performance
                    case .lighting: lighting
                    case .presets: presets
                    case .connection: connection
                    }
                    Text("BASILISK CONTROL  /  INDEPENDENT MACOS UTILITY")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .tracking(1.4).foregroundStyle(.tertiary).padding(.top, 4)
                }
                .padding(32)
            }
        }
        .background(background).tint(accent)
        .frame(minWidth: 920, minHeight: 700)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 32) {
            HStack(spacing: 10) {
                Image(systemName: "computermouse.fill").font(.system(size: 23)).foregroundStyle(accent)
                VStack(alignment: .leading, spacing: 3) {
                    Text("BASILISK").font(.system(size: 14, weight: .bold)).tracking(2)
                    Text("CONTROL").font(.system(size: 9, weight: .medium)).tracking(3).foregroundStyle(.secondary)
                }
            }.padding(.top, 27)
            VStack(spacing: 7) {
                ForEach(Page.allCases, id: \.self) { item in
                    Button {
                        page = item
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: item.symbol).frame(width: 18)
                            Text(item.rawValue).font(.system(size: 13, weight: .medium))
                            Spacer(minLength: 0)
                            if page == item { Circle().fill(accent).frame(width: 5, height: 5) }
                        }
                        .foregroundStyle(page == item ? accent : Color.secondary)
                        .padding(.horizontal, 13).padding(.vertical, 13)
                        .background(page == item ? accent.opacity(0.08) : .clear, in: RoundedRectangle(cornerRadius: 10))
                    }.buttonStyle(.plain)
                }
            }
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 7) {
                    Circle().fill(model.status == nil ? Color.secondary : accent).frame(width: 6, height: 6)
                    Text(model.status == nil ? "Waiting for mouse" : "Mouse connected")
                        .font(.system(size: 11, weight: .medium))
                }
                Text("Razer Basilisk Ultimate").font(.system(size: 10)).foregroundStyle(.secondary)
            }.padding(.horizontal, 6).padding(.bottom, 8)
        }
        .padding(20).frame(width: 190)
        .background(Color.white.opacity(0.018))
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 7) {
                Text(page.rawValue).font(.system(size: 28, weight: .semibold))
                Text(page.subtitle).font(.system(size: 13)).foregroundStyle(.secondary)
            }
            Spacer()
            Button { Task { await model.refresh() } } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }.controlSize(.large).disabled(model.busy).help("Read the current device settings (⌘R)")
        }
    }

    private var deviceCard: some View {
        HStack(spacing: 18) {
            MouseIllustration(glow: page == .lighting ? model.color : accent)
                .frame(width: 108, height: 160).padding(.horizontal, 16)
                .accessibilityLabel("Basilisk mouse illustration")
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("YOUR DEVICE").font(.system(size: 9, weight: .semibold)).tracking(2).foregroundStyle(accent)
                    Text("Basilisk Ultimate").font(.system(size: 23, weight: .semibold))
                    Text(model.status?.connection ?? "Connect via USB cable or 2.4 GHz receiver")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
                HStack(spacing: 25) {
                    readout("BATTERY", model.batteryLabel, symbol: model.status?.charging == true ? "bolt.fill" : "battery.100")
                    readout("CURRENT DPI", model.status?.x.map { String($0) } ?? "—", symbol: "scope")
                    readout("POLLING", model.status?.polling.map { "\($0) Hz" } ?? "—", symbol: "waveform.path")
                }
            }
            Spacer(minLength: 0)
        }
        .padding(20).frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [accent.opacity(0.06), Color.white.opacity(0.025)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(accent.opacity(0.13)))
    }

    private func readout(_ title: String, _ value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 8, weight: .semibold)).tracking(1.2).foregroundStyle(.secondary)
            Label(value, systemImage: symbol).font(.system(size: 13, weight: .medium, design: .monospaced))
        }
    }

    private var statusMessage: some View {
        HStack(alignment: .top, spacing: 10) {
            if model.busy {
                ProgressView().controlSize(.small).padding(.top, 2)
            } else {
                Image(systemName: model.isError ? "exclamationmark.circle" : "checkmark.circle")
                    .foregroundStyle(model.isError ? Color.orange : accent)
            }
            Text(model.busy ? "Communicating with your mouse…" : model.message)
                .font(.system(size: 11)).foregroundStyle(.secondary)
                .textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
        }.padding(13)
            .background((model.isError ? Color.orange : accent).opacity(0.045), in: RoundedRectangle(cornerRadius: 10))
            .accessibilityElement(children: .combine)
    }

    private var performance: some View {
        VStack(spacing: 18) {
            Card {
                sectionHeading("Sensitivity", detail: "Hardware DPI · 100–20,000 · steps of 50", symbol: "scope")
                dpiControl("Horizontal / X", value: $model.draftX)
                Toggle("Use the same DPI for both axes", isOn: $model.linkedAxes)
                    .font(.system(size: 12)).toggleStyle(.checkbox)
                if !model.linkedAxes { dpiControl("Vertical / Y", value: $model.draftY) }
                HStack {
                    ForEach([400, 800, 1600, 3200], id: \.self) { value in
                        Button("\(value)") { model.draftX = Double(value); model.draftY = Double(value) }
                            .controlSize(.small).help("Set draft DPI to \(value)")
                    }
                    Spacer()
                    Button("Apply DPI") { Task { await model.applyDPI() } }
                        .buttonStyle(.borderedProminent).disabled(!model.canApply)
                }
            }
            Card {
                sectionHeading("Polling rate", detail: "How often your mouse reports to your Mac", symbol: "waveform.path")
                HStack(spacing: 20) {
                    Picker("Polling rate", selection: $model.polling) {
                        Text("125 Hz").tag(125)
                        Text("500 Hz").tag(500)
                        Text("1000 Hz").tag(1000)
                    }.pickerStyle(.segmented).labelsHidden().frame(maxWidth: 340)
                    Spacer()
                    Button("Apply Rate") { Task { await model.applyPolling() } }
                        .buttonStyle(.borderedProminent).disabled(!model.canApply)
                }
            }
            HStack {
                Text("Changes take effect when you click Apply.").font(.system(size: 11)).foregroundStyle(.secondary)
                Spacer()
                Button("Load Current Settings") { model.loadDeviceValues() }.disabled(!model.canApply)
            }
        }.disabled(model.busy)
    }

    private func dpiControl(_ title: String, value: Binding<Double>) -> some View {
        VStack(spacing: 10) {
            HStack {
                Text(title).font(.system(size: 12)).foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(value.wrappedValue))").font(.system(size: 24, weight: .medium, design: .monospaced))
                Text("DPI").font(.system(size: 10, weight: .semibold)).foregroundStyle(.secondary)
                Stepper(title, value: value, in: 100...20000, step: 50).labelsHidden().fixedSize()
            }
            Slider(value: value, in: 100...20000, step: 50).accessibilityLabel(title + " DPI")
            HStack {
                Text("100"); Spacer(); Text("20,000")
            }.font(.system(size: 9, design: .monospaced)).foregroundStyle(.tertiary)
        }
    }

    private var lighting: some View {
        VStack(alignment: .leading, spacing: 18) {
            Card {
                sectionHeading("Chroma lighting", detail: "Choose a zone, effect, and brightness", symbol: "sparkles")
                Picker("Zone", selection: $model.zone) {
                    Text("All zones").tag(0)
                    Text("Scroll wheel").tag(1)
                    Text("Logo").tag(4)
                    Text("Left side").tag(0x11)
                    Text("Right side").tag(0x10)
                }.frame(maxWidth: 340)
                Picker("Effect", selection: $model.effect) {
                    Text("Static").tag(1)
                    Text("Spectrum").tag(3)
                    Text("Off").tag(0)
                }.pickerStyle(.segmented)
                if model.effect == 1 {
                    HStack {
                        ColorPicker("Color", selection: $model.color, supportsOpacity: false)
                        Spacer(minLength: 50)
                        ForEach(Array([accent, Color.cyan, Color.purple, Color.orange, Color.white].enumerated()), id: \.offset) { index, color in
                            Button { model.color = color } label: {
                                Circle().fill(color).frame(width: 19, height: 19)
                            }.buttonStyle(.plain).accessibilityLabel("Color swatch \(index + 1)")
                        }
                    }
                }
                HStack {
                    Text("Brightness").font(.system(size: 12))
                    Slider(value: $model.brightness, in: 0...100, step: 1).accessibilityLabel("Brightness")
                    Text("\(Int(model.brightness))%")
                        .font(.system(size: 12, design: .monospaced)).frame(width: 42, alignment: .trailing)
                }.disabled(model.effect == 0)
                HStack {
                    Text("Lighting values are a draft until applied.").font(.system(size: 11)).foregroundStyle(.secondary)
                    Spacer()
                    Button("Apply Lighting") { Task { await model.applyLighting() } }
                        .buttonStyle(.borderedProminent).disabled(!model.canApply)
                }
            }.disabled(model.busy)
            Text("The illustration previews your chosen color. Existing device effects are not read back. Lighting commands follow the Basilisk Ultimate protocol; visual results still need testing with your firmware.")
                .font(.system(size: 11)).foregroundStyle(.secondary)
        }
    }

    private var presets: some View {
        VStack(spacing: 18) {
            Card {
                sectionHeading("Performance presets", detail: "Saved on this Mac · available from the menu bar", symbol: "square.stack")
                if model.presets.isEmpty {
                    Text("No presets yet. Save your draft settings below.").foregroundStyle(.secondary)
                }
                ForEach(model.presets) { preset in
                    HStack(spacing: 14) {
                        Image(systemName: "scope").foregroundStyle(accent)
                            .frame(width: 34, height: 34).background(accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                        VStack(alignment: .leading, spacing: 5) {
                            Text(preset.name).font(.system(size: 13, weight: .medium))
                            Text("\(preset.x) × \(preset.y) DPI  ·  \(preset.polling) Hz")
                                .font(.system(size: 11, design: .monospaced)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Apply") { Task { await model.applyPreset(preset) } }.disabled(!model.canApply)
                        Button { model.removePreset(preset.id) } label: { Image(systemName: "trash") }
                            .buttonStyle(.borderless).foregroundStyle(.secondary).help("Delete preset “\(preset.name)”")
                    }.padding(.vertical, 5)
                }
            }
            Card {
                sectionHeading("Save draft as preset", detail: "\(Int(model.draftX)) × \(model.yValue) DPI · \(model.polling) Hz", symbol: "plus.circle")
                HStack {
                    TextField("Preset name", text: $model.presetName).textFieldStyle(.roundedBorder)
                        .onSubmit { model.savePreset() }
                    Button("Save Preset") { model.savePreset() }
                        .disabled(model.presetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                Text("Set your draft DPI and polling rate in Performance first. Saving a preset does not change the mouse. A matching name replaces that preset.")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Text("Presets apply DPI and polling in sequence. If one command fails, earlier changes may remain applied; the app refreshes the current readings.")
                .font(.system(size: 11)).foregroundStyle(.secondary)
        }.disabled(model.busy)
    }

    private var connection: some View {
        VStack(spacing: 18) {
            Card {
                sectionHeading("Device connection", detail: "Direct USB HID · no kernel extension", symbol: "cable.connector")
                LabeledContent("Model", value: "Razer Basilisk Ultimate")
                LabeledContent("Transport", value: model.status?.connection ?? "Disconnected")
                LabeledContent("USB ID", value: model.status.map { String(format: "1532:%04X", $0.productID) } ?? "1532:0086 / 1532:0088")
                LabeledContent("Last reading") {
                    if let date = model.updatedAt { Text(date, style: .time) }
                    else { Text("No reading yet") }
                }
                if let charging = model.status?.charging {
                    LabeledContent("Battery status", value: charging ? "Charging" : "Not charging")
                }
            }.font(.system(size: 12))
            Card {
                sectionHeading("Get connected", detail: "Use the mouse’s own receiver or USB cable", symbol: "checkmark.circle")
                Text("1. Connect the Basilisk Ultimate receiver or a USB data cable. Turn the mouse on and move it to wake it.\n\n2. Close other Razer configuration apps so they do not compete for replies. If you have multiple Basilisk mice, connect one at a time. The wired connection takes priority.\n\n3. Click Refresh. If access is denied, enable Basilisk Control in Input Monitoring, then quit and reopen it.")
                    .font(.system(size: 12)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                HStack {
                    Button("Open Input Monitoring") { model.openInputMonitoring() }
                    Spacer()
                    Button("Retry Connection") { Task { await model.refresh(loadDrafts: true) } }
                        .buttonStyle(.borderedProminent).disabled(model.busy)
                }
            }
            Text("This release controls DPI, polling, and lighting. Button remapping, macros, clutch assignments, hardware DPI stages, and onboard profile editing are not implemented. The scroll resistance wheel is a mechanical control.")
                .font(.system(size: 11)).foregroundStyle(.secondary)
        }
    }

    private func sectionHeading(_ title: String, detail: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: symbol).font(.system(size: 16)).foregroundStyle(accent).padding(.top, 2)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.system(size: 15, weight: .semibold))
                Text(detail).font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer()
        }.padding(.bottom, 3)
    }
}

private struct Card<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        VStack(alignment: .leading, spacing: 18) { content }
            .padding(22).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.025), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.065)))
    }
}

private struct MouseIllustration: View {
    var glow: Color
    var body: some View {
        ZStack {
            Ellipse().fill(glow.opacity(0.13)).blur(radius: 18).padding(15)
            MouseBody().fill(LinearGradient(colors: [Color(white: 0.18), Color(white: 0.065)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: .black.opacity(0.55), radius: 12, x: 7, y: 9)
            MouseBody().stroke(Color.white.opacity(0.18), lineWidth: 1)
            GeometryReader { proxy in
                let w = proxy.size.width, h = proxy.size.height
                Path { p in
                    p.move(to: CGPoint(x: w * 0.47, y: h * 0.03))
                    p.addLine(to: CGPoint(x: w * 0.47, y: h * 0.38))
                    p.move(to: CGPoint(x: w * 0.17, y: h * 0.38))
                    p.addQuadCurve(to: CGPoint(x: w * 0.80, y: h * 0.40), control: CGPoint(x: w * 0.48, y: h * 0.44))
                }.stroke(.black.opacity(0.75), lineWidth: 2)
                RoundedRectangle(cornerRadius: 4).fill(glow.opacity(0.9))
                    .frame(width: w * 0.09, height: h * 0.18).position(x: w * 0.49, y: h * 0.19)
                Image(systemName: "bolt.shield.fill").font(.system(size: 21, weight: .light))
                    .foregroundStyle(glow.opacity(0.8)).position(x: w * 0.52, y: h * 0.71)
                Path { p in
                    p.move(to: CGPoint(x: w * 0.23, y: h * 0.49))
                    p.addCurve(to: CGPoint(x: w * 0.33, y: h * 0.91), control1: CGPoint(x: w * 0.17, y: h * 0.72), control2: CGPoint(x: w * 0.07, y: h * 0.82))
                    p.move(to: CGPoint(x: w * 0.85, y: h * 0.44))
                    p.addQuadCurve(to: CGPoint(x: w * 0.77, y: h * 0.91), control: CGPoint(x: w * 0.99, y: h * 0.81))
                }.stroke(glow.opacity(0.7), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            }
        }.rotationEffect(.degrees(-12))
    }
}

private struct MouseBody: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        return Path { p in
            p.move(to: CGPoint(x: w * 0.20, y: h * 0.13))
            p.addCurve(to: CGPoint(x: w * 0.79, y: h * 0.09), control1: CGPoint(x: w * 0.24, y: -h * 0.03), control2: CGPoint(x: w * 0.69, y: -h * 0.02))
            p.addCurve(to: CGPoint(x: w * 0.88, y: h * 0.83), control1: CGPoint(x: w * 0.88, y: h * 0.28), control2: CGPoint(x: w, y: h * 0.65))
            p.addCurve(to: CGPoint(x: w * 0.16, y: h * 0.90), control1: CGPoint(x: w * 0.83, y: h * 1.04), control2: CGPoint(x: w * 0.35, y: h * 1.06))
            p.addCurve(to: CGPoint(x: w * 0.20, y: h * 0.13), control1: CGPoint(x: -w * 0.14, y: h * 0.77), control2: CGPoint(x: w * 0.19, y: h * 0.52))
            p.closeSubpath()
        }
    }
}
