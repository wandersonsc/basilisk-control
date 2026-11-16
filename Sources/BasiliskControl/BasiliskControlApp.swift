// SPDX-License-Identifier: MIT
import SwiftUI
import AppKit

@main
@MainActor
struct BasiliskControlApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("Basilisk Control", id: "main") {
            ContentView(model: model)
                .preferredColorScheme(.dark)
                .task { model.startMonitoring() }
        }
        .defaultSize(width: 1040, height: 760)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .toolbar) {
                Button("Refresh Mouse") { Task { await model.refresh() } }
                    .keyboardShortcut("r", modifiers: .command).disabled(model.busy)
            }
        }

        MenuBarExtra {
            MenuPanel(model: model)
        } label: {
            Label(model.menuLabel, systemImage: "computermouse")
        }
    }
}

@MainActor
struct MenuPanel: View {
    @ObservedObject var model: AppModel
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        Text("Basilisk Ultimate")
        Text(model.status?.connection ?? "Not connected")
        if let status = model.status {
            Text("Battery: \(model.batteryLabel)\(status.charging == true ? " • Charging" : "")")
            if let x = status.x, let y = status.y { Text("DPI: \(x) × \(y)") }
        }
        Divider()
        Menu("Apply Preset") {
            ForEach(model.presets) { preset in
                Button(preset.name) { Task { await model.applyPreset(preset) } }
            }
        }.disabled(!model.canApply || model.presets.isEmpty)
        Button("Refresh") { Task { await model.refresh() } }.disabled(model.busy)
        Button("Open Basilisk Control") {
            openWindow(id: "main"); NSApp.activate(ignoringOtherApps: true)
        }
        Divider()
        Button("Quit") { NSApp.terminate(nil) }.keyboardShortcut("q")
    }
}
