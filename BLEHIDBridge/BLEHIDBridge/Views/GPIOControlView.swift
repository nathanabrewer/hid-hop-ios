/*
 * HID-HOP - GPIO Control View
 *
 * Control LEDs, relays, and monitor inputs
 */

import SwiftUI

struct GPIOControlView: View {
    @EnvironmentObject var bleManager: BLEManager
    @State private var refreshTimer: Timer?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // LED Control Section
                LEDControlSection()

                // Relay Control Section
                RelayControlSection()

                // Digital Inputs Section
                DigitalInputsSection()

                // Analog Inputs Section
                AnalogInputsSection()

                // Refresh Button
                Button(action: {
                    bleManager.requestGpioState()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh State")
                    }
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.hopPurple.gradient)
                    )
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .onAppear {
            // Request initial state
            bleManager.requestGpioState()

            // Set up periodic refresh for inputs
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                if bleManager.isConnected {
                    bleManager.requestGpioState()
                }
            }
        }
        .onDisappear {
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
    }
}

// MARK: - LED Control Section

struct LEDControlSection: View {
    @EnvironmentObject var bleManager: BLEManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.hopGold)
                Text("LEDs")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
            }

            HStack(spacing: 16) {
                ForEach(0..<3) { index in
                    LEDButton(index: index)
                }
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

struct LEDButton: View {
    @EnvironmentObject var bleManager: BLEManager
    let index: Int

    private var isOn: Bool {
        bleManager.gpioState.ledOn(index)
    }

    private var pinLabel: String {
        switch index {
        case 0: return "P0.23"
        case 1: return "P0.22"
        case 2: return "P0.24"
        default: return "?"
        }
    }

    var body: some View {
        Button(action: {
            bleManager.setLed(index, on: !isOn)
        }) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(isOn ? Color.hopGold : Color(.systemGray4))
                        .frame(width: 50, height: 50)

                    Image(systemName: isOn ? "lightbulb.fill" : "lightbulb")
                        .font(.system(size: 24))
                        .foregroundColor(isOn ? .black : .gray)
                }

                Text("LED\(index)")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.semibold)

                Text(pinLabel)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Relay Control Section

struct RelayControlSection: View {
    @EnvironmentObject var bleManager: BLEManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.hopPink)
                Text("Relays / Outputs")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(0..<7) { index in
                    RelayButton(index: index)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

struct RelayButton: View {
    @EnvironmentObject var bleManager: BLEManager
    let index: Int

    private var isOn: Bool {
        bleManager.gpioState.relayOn(index)
    }

    private var pinLabel: String {
        "P0.\(4 + index)"
    }

    var body: some View {
        Button(action: {
            bleManager.setRelay(index, on: !isOn)
        }) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isOn ? Color.hopPink : Color(.systemGray4))
                        .frame(width: 50, height: 50)

                    Image(systemName: isOn ? "power.circle.fill" : "power.circle")
                        .font(.system(size: 24))
                        .foregroundColor(isOn ? .white : .gray)
                }

                Text("R\(index)")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.semibold)

                Text(pinLabel)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Digital Inputs Section

struct DigitalInputsSection: View {
    @EnvironmentObject var bleManager: BLEManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(.hopCyan)
                Text("Digital Inputs")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
            }

            HStack(spacing: 20) {
                DigitalInputIndicator(index: 0, pin: "P0.20")
                DigitalInputIndicator(index: 1, pin: "P0.21")
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

struct DigitalInputIndicator: View {
    @EnvironmentObject var bleManager: BLEManager
    let index: Int
    let pin: String

    private var isActive: Bool {
        bleManager.gpioState.dinActive(index)
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(isActive ? Color.hopCyan : Color(.systemGray4))
                    .frame(width: 50, height: 50)

                Image(systemName: isActive ? "circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isActive ? .white : .gray)
            }

            Text("DIN\(index)")
                .font(.system(.caption, design: .rounded))
                .fontWeight(.semibold)

            Text(pin)
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.secondary)

            Text(isActive ? "Active" : "Idle")
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(isActive ? .hopCyan : .secondary)
        }
    }
}

// MARK: - Analog Inputs Section

struct AnalogInputsSection: View {
    @EnvironmentObject var bleManager: BLEManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "waveform.path")
                    .foregroundColor(.hopPurple)
                Text("Analog Inputs")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
            }

            HStack(spacing: 20) {
                AnalogInputGauge(index: 0, pin: "P0.2")
                AnalogInputGauge(index: 1, pin: "P0.3")
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

struct AnalogInputGauge: View {
    @EnvironmentObject var bleManager: BLEManager
    let index: Int
    let pin: String

    private var rawValue: UInt16 {
        index == 0 ? bleManager.gpioState.ain0Value : bleManager.gpioState.ain1Value
    }

    private var voltage: Double {
        bleManager.gpioState.ainVoltage(index)
    }

    private var percentage: Double {
        Double(rawValue) / 4095.0
    }

    var body: some View {
        VStack(spacing: 8) {
            // Gauge
            ZStack {
                Circle()
                    .stroke(Color(.systemGray4), lineWidth: 8)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: percentage)
                    .stroke(
                        LinearGradient(colors: [.hopPurple, .hopPink], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text(String(format: "%.2f", voltage))
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.bold)
                    Text("V")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }

            Text("AIN\(index)")
                .font(.system(.caption, design: .rounded))
                .fontWeight(.semibold)

            Text(pin)
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.secondary)

            Text("Raw: \(rawValue)")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    GPIOControlView()
        .environmentObject(BLEManager())
}
