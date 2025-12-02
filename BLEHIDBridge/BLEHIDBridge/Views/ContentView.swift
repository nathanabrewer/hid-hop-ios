/*
 * HID-HOP - Main Content View
 * Drop the beat, control the fleet
 */

import SwiftUI

// MARK: - Hip-Hop Color Theme

extension Color {
    static let hopPurple = Color(red: 0.6, green: 0.2, blue: 0.8)
    static let hopGold = Color(red: 1.0, green: 0.84, blue: 0.0)
    static let hopPink = Color(red: 1.0, green: 0.4, blue: 0.6)
    static let hopCyan = Color(red: 0.0, green: 0.9, blue: 0.9)
    static let hopDark = Color(red: 0.1, green: 0.1, blue: 0.15)
}

struct ContentView: View {
    @EnvironmentObject var bleManager: BLEManager
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Connection status bar
                ConnectionStatusBar()

                // Main content
                if bleManager.isConnected {
                    TabView(selection: $selectedTab) {
                        TouchpadView()
                            .tabItem {
                                Label("Pad", systemImage: "hand.point.up.left.fill")
                            }
                            .tag(0)

                        KeyboardView()
                            .tabItem {
                                Label("Keys", systemImage: "pianokeys")
                            }
                            .tag(1)

                        QuickActionsView()
                            .tabItem {
                                Label("Beats", systemImage: "bolt.fill")
                            }
                            .tag(2)

                        SettingsView()
                            .tabItem {
                                Label("Tune", systemImage: "slider.horizontal.3")
                            }
                            .tag(3)
                    }
                    .tint(.hopPurple)
                    .disabled(bleManager.needsPinVerification)
                    .blur(radius: bleManager.needsPinVerification ? 10 : 0)
                } else {
                    DeviceScanView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 4) {
                        Text("HID")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(.hopPurple)
                        Text("-")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(.hopGold)
                        Text("HOP")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(.hopPink)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $bleManager.showPinPrompt) {
            PinEntryView()
        }
        .onChange(of: bleManager.isConnected) { _, connected in
            // When first connected, show PIN prompt
            if connected && !bleManager.isAuthenticated {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    bleManager.needsPinVerification = true
                    bleManager.showPinPrompt = true
                }
            }
        }
    }
}

// MARK: - PIN Entry View

struct PinEntryView: View {
    @EnvironmentObject var bleManager: BLEManager
    @State private var pin: String = ""
    @State private var showError: Bool = false
    @FocusState private var pinFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Lock icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.hopPurple.opacity(0.3), .hopPink.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 100, height: 100)

                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.hopPurple, .hopPink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(spacing: 8) {
                    Text("Enter PIN")
                        .font(.system(size: 24, weight: .bold, design: .rounded))

                    Text("Default PIN is 123456")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                }

                // PIN field
                SecureField("PIN", text: $pin)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .font(.system(size: 24, weight: .medium, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 40)
                    .focused($pinFieldFocused)

                // Attempts remaining
                if bleManager.pinAttemptsRemaining < 3 {
                    Text("\(bleManager.pinAttemptsRemaining) attempts remaining")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.red)
                }

                if showError {
                    Text("Incorrect PIN")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.red)
                }

                Spacer()

                // Verify button
                Button(action: verifyPin) {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                        Text("Unlock")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.hopPurple, .hopPink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
                .disabled(pin.count < 4)
                .opacity(pin.count < 4 ? 0.5 : 1)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .navigationTitle("Authentication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Disconnect") {
                        bleManager.disconnect()
                    }
                    .foregroundColor(.red)
                }
            }
            .onAppear {
                pinFieldFocused = true
            }
            .onChange(of: bleManager.isAuthenticated) { _, authenticated in
                if authenticated {
                    showError = false
                }
            }
            .onChange(of: bleManager.pinAttemptsRemaining) { oldVal, newVal in
                if newVal < oldVal {
                    showError = true
                    pin = ""
                }
            }
        }
        .interactiveDismissDisabled(true)
    }

    private func verifyPin() {
        guard pin.count >= 4 else { return }
        showError = false
        bleManager.verifyPin(pin)
    }
}

// MARK: - Connection Status Bar

struct ConnectionStatusBar: View {
    @EnvironmentObject var bleManager: BLEManager
    @State private var pulseAnimation = false

    var body: some View {
        HStack {
            // Animated status indicator
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.3))
                    .frame(width: 20, height: 20)
                    .scaleEffect(pulseAnimation ? 1.5 : 1.0)
                    .opacity(pulseAnimation ? 0 : 0.5)

                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
            }
            .onAppear {
                if bleManager.connectionState == .scanning || bleManager.connectionState == .connecting {
                    withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                        pulseAnimation = true
                    }
                }
            }
            .onChange(of: bleManager.connectionState) { _, newState in
                if newState == .scanning || newState == .connecting {
                    withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                        pulseAnimation = true
                    }
                } else {
                    pulseAnimation = false
                }
            }

            Text(statusText)
                .font(.system(.caption, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            Spacer()

            if bleManager.isConnected {
                Button(action: {
                    bleManager.disconnect()
                }) {
                    Text("Drop")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.red.gradient)
                        )
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemBackground).opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var statusColor: Color {
        switch bleManager.connectionState {
        case .connected:
            return .hopCyan
        case .connecting:
            return .hopGold
        case .disconnected:
            return .hopPink
        case .scanning:
            return .hopPurple
        }
    }

    private var statusText: String {
        switch bleManager.connectionState {
        case .connected:
            return "Vibin' with \(bleManager.connectedDeviceName ?? "device")"
        case .connecting:
            return "Linking up..."
        case .disconnected:
            return "On standby"
        case .scanning:
            return "Seeking the beat..."
        }
    }
}

// MARK: - Device Scan View

struct DeviceScanView: View {
    @EnvironmentObject var bleManager: BLEManager
    @State private var rotationAngle: Double = 0

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Animated icon
            ZStack {
                // Outer ring
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.hopPurple, .hopPink, .hopGold, .hopCyan, .hopPurple],
                            center: .center
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(rotationAngle))

                Image("hopguy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
            }
            .onAppear {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    rotationAngle = 360
                }
            }

            VStack(spacing: 8) {
                Text("Drop In")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.hopPurple, .hopPink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("Power up your HID-HOP and let's roll")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            if bleManager.isScanning {
                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(Color.hopPurple)
                            .frame(width: 8, height: 8)
                            .scaleEffect(bleManager.isScanning ? 1.0 : 0.5)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(i) * 0.2),
                                value: bleManager.isScanning
                            )
                    }
                }
                .padding()
            }

            // Device list
            if !bleManager.discoveredDevices.isEmpty {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(bleManager.discoveredDevices) { device in
                            DeviceRow(device: device)
                        }
                    }
                    .padding(.horizontal)
                }
            }

            Spacer()

            Button(action: {
                if bleManager.isScanning {
                    bleManager.stopScanning()
                } else {
                    bleManager.startScanning()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: bleManager.isScanning ? "stop.fill" : "waveform")
                        .font(.system(size: 18, weight: .bold))
                    Text(bleManager.isScanning ? "Hold Up" : "Scan the Scene")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    bleManager.isScanning ?
                    AnyShapeStyle(Color.hopPink.gradient) :
                    AnyShapeStyle(LinearGradient(
                        colors: [.hopPurple, .hopPink],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                )
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: bleManager.isScanning ? .hopPink.opacity(0.4) : .hopPurple.opacity(0.4), radius: 8, y: 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .onAppear {
            bleManager.startScanning()
        }
    }
}

struct DeviceRow: View {
    @EnvironmentObject var bleManager: BLEManager
    let device: DiscoveredDevice

    var body: some View {
        Button(action: {
            bleManager.connect(to: device)
        }) {
            HStack {
                // Signal strength indicator
                ZStack {
                    Circle()
                        .fill(signalColor.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: "wave.3.right")
                        .font(.system(size: 20))
                        .foregroundColor(signalColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.primary)

                    Text("Signal: \(signalStrength)")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.hopPurple, .hopPink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [.hopPurple.opacity(0.3), .hopPink.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
    }

    private var signalStrength: String {
        if device.rssi >= -50 { return "Strong" }
        if device.rssi >= -70 { return "Good" }
        if device.rssi >= -85 { return "Fair" }
        return "Weak"
    }

    private var signalColor: Color {
        if device.rssi >= -50 { return .hopCyan }
        if device.rssi >= -70 { return .hopGold }
        if device.rssi >= -85 { return .hopPink }
        return .gray
    }
}

#Preview {
    ContentView()
        .environmentObject(BLEManager())
}
