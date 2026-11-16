// SPDX-License-Identifier: MIT
import Foundation
import BasiliskHID

struct MouseStatus: Sendable {
    var productID: Int
    var x: Int?
    var y: Int?
    var polling: Int?
    var battery: Int?
    var charging: Bool?
    var warning: String
    var connection: String { productID == 0x0086 ? "USB cable" : "2.4 GHz receiver" }
}

struct DeviceFailure: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

/// Actor serializes every report exchange away from the main thread.
actor DeviceService {
    func read() throws -> MouseStatus {
        var raw = BCStatus()
        var error = [CChar](repeating: 0, count: 1024)
        let code = bc_read_status(&raw, &error, 1024)
        let message = String(cString: error)
        guard code == 0 else { throw DeviceFailure(message: message) }
        return MouseStatus(productID: Int(raw.product_id),
            x: raw.valid & 1 != 0 ? Int(raw.dpi_x) : nil,
            y: raw.valid & 1 != 0 ? Int(raw.dpi_y) : nil,
            polling: raw.valid & 2 != 0 ? Int(raw.polling) : nil,
            battery: raw.valid & 4 != 0 ? Int(raw.battery_percent) : nil,
            charging: raw.valid & 8 != 0 ? raw.charging != 0 : nil,
            warning: message)
    }

    func setDPI(x: Int, y: Int) throws {
        var error = [CChar](repeating: 0, count: 1024)
        let result = bc_set_dpi(Int32(x), Int32(y), &error, 1024)
        if result != 0 { throw DeviceFailure(message: String(cString: error)) }
    }

    func setPolling(_ hz: Int) throws {
        var error = [CChar](repeating: 0, count: 1024)
        let result = bc_set_polling(Int32(hz), &error, 1024)
        if result != 0 { throw DeviceFailure(message: String(cString: error)) }
    }

    func setLighting(zone: Int, effect: Int, rgb: [Int], brightness: Int) throws {
        guard rgb.count == 3 else { throw DeviceFailure(message: "Choose a valid RGB color.") }
        var error = [CChar](repeating: 0, count: 1024)
        let result = bc_set_lighting(Int32(zone), Int32(effect), Int32(rgb[0]), Int32(rgb[1]),
            Int32(rgb[2]), Int32(brightness), &error, 1024)
        if result != 0 { throw DeviceFailure(message: String(cString: error)) }
    }
}
