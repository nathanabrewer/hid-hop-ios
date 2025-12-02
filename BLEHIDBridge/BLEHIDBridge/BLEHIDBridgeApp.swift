/*
 * Brewer BLE HID Bridge - iOS App Entry Point
 */

import SwiftUI

@main
struct BLEHIDBridgeApp: App {
    @StateObject private var bleManager = BLEManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bleManager)
        }
    }
}
