// SPDX-License-Identifier: MIT
import SwiftUI
import AppKit

struct Preset: Identifiable, Codable {
    var id = UUID()
    var name: String
    var x: Int
    var y: Int
    var polling: Int
    var isValid: Bool {
        (100...20000).contains(x) && (100...20000).contains(y) && x % 50 == 0 && y % 50 == 0 &&
            [125, 500, 1000].contains(polling) && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && name.count <= 48
    }
}

@MainActor
final class AppModel: ObservableObject {
    @Published var status: MouseStatus?
    @Published var busy = false
    @Published var hasScanned = false
    @Published var message = "Connect the USB cable or receiver to get started."
    @Published var isError = false
    @Published var updatedAt: Date?
    @Published var draftX = 1600.0
    @Published var draftY = 1600.0
    @Published var linkedAxes = true
    @Published var polling = 1000
    @Published var zone = 0
    @Published var effect = 1
    @Published var color = Color(red: 0.36, green: 0.95, blue: 0.63)
    @Published var brightness = 70.0
    @Published var presetName = ""
    @Published var presets: [Preset] = []
    private let service = DeviceService()
    private let storageKey = "BasiliskControl.presets.v1"
    private var pollingTask: Task<Void, Never>?

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([Preset].self, from: data) {
            presets = Array(saved.filter(\.isValid).prefix(30))
        } else {
            presets = [Preset(name: "Precision", x: 800, y: 800, polling: 1000),
                Preset(name: "Everyday", x: 1600, y: 1600, polling: 1000),
                Preset(name: "Fast", x: 3200, y: 3200, polling: 1000)]
        }
    }

    var canApply: Bool { status != nil && !busy }
    var yValue: Int { linkedAxes ? Int(draftX) : Int(draftY) }
    var batteryLabel: String { status?.battery.map { "\($0)%" } ?? "—" }
    var menuLabel: String { status == nil ? "Basilisk" : "\(batteryLabel)" }

    func startMonitoring() {
        guard pollingTask == nil else { return }
        pollingTask = Task {
            await refresh(loadDrafts: true)
            while !Task.isCancelled {
                do { try await Task.sleep(nanoseconds: 30_000_000_000) } catch { return }
                await refresh(quiet: true)
            }
        }
    }

    func refresh(loadDrafts: Bool = false, quiet: Bool = false) async {
        guard !busy else { return }
        busy = true
        defer { busy = false; hasScanned = true }
        do {
            let next = try await service.read()
            let newlyConnected = status == nil || status?.productID != next.productID
            status = next; updatedAt = Date()
            if loadDrafts || newlyConnected { loadDeviceValues() }
            if !quiet || newlyConnected {
                message = next.warning.isEmpty ? "Connected. Device readings are up to date." : next.warning
                isError = !next.warning.isEmpty
            } else if !next.warning.isEmpty {
                message = next.warning; isError = true
            } else if isError {
                message = "Connected. Device readings are up to date."; isError = false
            }
        } catch {
            status = nil; updatedAt = nil
            message = error.localizedDescription; isError = true
        }
    }

    func loadDeviceValues() {
        if let x = status?.x, let y = status?.y {
            draftX = Double(x); draftY = Double(y); linkedAxes = x == y
        }
        if let hz = status?.polling { polling = hz }
    }

    func applyDPI() async {
        let x = Int(draftX), y = yValue
        await perform(success: "DPI applied and verified: \(x) × \(y).") {
            try await self.service.setDPI(x: x, y: y)
        }
    }

    func applyPolling() async {
        let hz = polling
        await perform(success: "Polling rate applied and verified: \(hz) Hz.") {
            try await self.service.setPolling(hz)
        }
    }

    func applyLighting() async {
        guard let rgbColor = NSColor(color).usingColorSpace(.sRGB) else {
            message = "This color could not be converted to RGB."; isError = true; return
        }
        let rgb = [rgbColor.redComponent, rgbColor.greenComponent, rgbColor.blueComponent]
            .map { Int(($0 * 255).rounded()) }
        let selectedZone = zone, selectedEffect = effect, level = Int(brightness)
        await perform(success: "Lighting commands acknowledged by the mouse.") {
            try await self.service.setLighting(zone: selectedZone, effect: selectedEffect, rgb: rgb, brightness: level)
        }
    }

    func applyPreset(_ preset: Preset) async {
        guard preset.isValid else { return }
        draftX = Double(preset.x); draftY = Double(preset.y)
        linkedAxes = preset.x == preset.y; polling = preset.polling
        await perform(success: "“\(preset.name)” applied. DPI and polling verified.") {
            try await self.service.setDPI(x: preset.x, y: preset.y)
            try await self.service.setPolling(preset.polling)
        }
    }

    private func perform(success: String, operation: () async throws -> Void) async {
        guard canApply else { return }
        busy = true
        var failure: String?
        do { try await operation() } catch { failure = error.localizedDescription }
        // Refresh even after errors: a command may have reached the mouse.
        do {
            status = try await service.read(); updatedAt = Date()
        } catch {
            status = nil; updatedAt = nil
            if failure == nil { failure = "The command completed, but refreshing failed: \(error.localizedDescription)" }
        }
        if failure == nil, let warning = status?.warning, !warning.isEmpty {
            failure = "\(success) Some readings are unavailable: \(warning)"
        }
        message = failure ?? success; isError = failure != nil
        busy = false
    }

    func savePreset() {
        let name = presetName.trimmingCharacters(in: .whitespacesAndNewlines)
        let preset = Preset(name: name, x: Int(draftX), y: yValue, polling: polling)
        guard preset.isValid else { message = "Use a name of 1–48 characters and valid DPI values in steps of 50."; isError = true; return }
        if let index = presets.firstIndex(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            presets[index] = preset
        } else if presets.count < 30 { presets.append(preset) }
        else { message = "You can save up to 30 presets. Remove one first."; isError = true; return }
        persist(); presetName = ""; message = "Preset saved on this Mac."; isError = false
    }

    func removePreset(_ id: UUID) { presets.removeAll { $0.id == id }; persist() }
    private func persist() {
        if let data = try? JSONEncoder().encode(presets) { UserDefaults.standard.set(data, forKey: storageKey) }
    }

    func openInputMonitoring() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
            NSWorkspace.shared.open(url)
        }
    }
}
