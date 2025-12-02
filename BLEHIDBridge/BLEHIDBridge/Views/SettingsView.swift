/*
 * HID-HOP - Settings View
 */

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var bleManager: BLEManager
    @AppStorage("touchpadSensitivity") private var touchpadSensitivity: Double = 1.5
    @AppStorage("scrollSensitivity") private var scrollSensitivity: Double = 1.0
    @AppStorage("hapticFeedback") private var hapticFeedback: Bool = true

    // Device configuration state
    @State private var deviceName: String = ""
    @State private var showingNameSheet: Bool = false
    @State private var showingPinSheet: Bool = false
    @State private var newPin: String = ""
    @State private var confirmPin: String = ""
    @State private var pinError: String?

    // Track the previous name to detect changes
    @State private var previousDeviceName: String = ""

    var body: some View {
        Form {
            // Device info section
            Section("Connected Device") {
                if bleManager.isConnected {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(bleManager.connectedDeviceName ?? "Unknown")
                            .foregroundColor(.secondary)
                        // Show checkmark briefly when name changes
                        if bleManager.connectedDeviceName != previousDeviceName && !previousDeviceName.isEmpty {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .onChange(of: bleManager.connectedDeviceName) { oldValue, newValue in
                        if let old = oldValue, let new = newValue, old != new {
                            previousDeviceName = old
                            // Clear the checkmark after a delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                previousDeviceName = new
                            }
                        }
                    }
                    LabeledContent("Protocol Version", value: "1.0")

                    Button(role: .destructive) {
                        bleManager.disconnect()
                    } label: {
                        Text("Disconnect")
                    }
                } else {
                    Text("Not connected")
                        .foregroundColor(.secondary)
                }
            }

            // Device configuration section
            Section("Device Configuration") {
                Button {
                    deviceName = bleManager.connectedDeviceName ?? ""
                    showingNameSheet = true
                } label: {
                    HStack {
                        Text("Change Device Name")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(!bleManager.isConnected)

                Button {
                    newPin = ""
                    confirmPin = ""
                    pinError = nil
                    showingPinSheet = true
                } label: {
                    HStack {
                        Text("Set Access PIN")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(!bleManager.isConnected)

                Button(role: .destructive) {
                    bleManager.clearPin()
                } label: {
                    Text("Remove PIN Protection")
                }
                .disabled(!bleManager.isConnected)
            }

            // Sensitivity settings
            Section("Touchpad") {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Cursor Sensitivity")
                        Spacer()
                        Text(String(format: "%.1fx", touchpadSensitivity))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $touchpadSensitivity, in: 0.5...3.0, step: 0.1)
                }

                VStack(alignment: .leading) {
                    HStack {
                        Text("Scroll Sensitivity")
                        Spacer()
                        Text(String(format: "%.1fx", scrollSensitivity))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $scrollSensitivity, in: 0.5...3.0, step: 0.1)
                }
            }

            // Haptic settings
            Section("Feedback") {
                Toggle("Haptic Feedback", isOn: $hapticFeedback)
            }

            // About section
            Section("About") {
                LabeledContent("App Version", value: "1.0.0")
                LabeledContent("Build", value: "1")

                Link("View on GitHub", destination: URL(string: "https://github.com/nathanabrewer/hid-hop-ios")!)
            }
        }
        .sheet(isPresented: $showingNameSheet) {
            NavigationStack {
                Form {
                    Section {
                        TextField("Device Name", text: $deviceName)
                            .autocorrectionDisabled()
                    } footer: {
                        Text("Maximum 20 characters. This name will appear when scanning for devices.")
                    }
                }
                .navigationTitle("Change Device Name")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingNameSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let trimmedName = String(deviceName.prefix(20))
                            if !trimmedName.isEmpty {
                                bleManager.setDeviceName(trimmedName)
                            }
                            showingNameSheet = false
                        }
                        .disabled(deviceName.isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingPinSheet) {
            NavigationStack {
                Form {
                    Section {
                        SecureField("New PIN", text: $newPin)
                            .keyboardType(.numberPad)
                        SecureField("Confirm PIN", text: $confirmPin)
                            .keyboardType(.numberPad)
                    } footer: {
                        Text("PIN must be 4-8 digits. This will be required to use the device.")
                    }

                    if let error = pinError {
                        Section {
                            Text(error)
                                .foregroundColor(.red)
                        }
                    }
                }
                .navigationTitle("Set Access PIN")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingPinSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            if validateAndSetPin() {
                                showingPinSheet = false
                            }
                        }
                        .disabled(newPin.count < 4 || confirmPin.count < 4)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private func validateAndSetPin() -> Bool {
        // Validate PIN is digits only
        guard newPin.allSatisfy({ $0.isNumber }) else {
            pinError = "PIN must contain only numbers"
            return false
        }

        // Validate length
        guard newPin.count >= 4 && newPin.count <= 8 else {
            pinError = "PIN must be 4-8 digits"
            return false
        }

        // Validate confirmation matches
        guard newPin == confirmPin else {
            pinError = "PINs do not match"
            return false
        }

        // Set the PIN
        bleManager.setPin(newPin)
        return true
    }
}

#Preview {
    SettingsView()
        .environmentObject(BLEManager())
}
