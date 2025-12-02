/*
 * HID-HOP - BLE Manager
 *
 * Handles Bluetooth Low Energy communication with the HID-HOP dongle.
 */

import Foundation
import CoreBluetooth
import Combine

// MARK: - Connection State

enum ConnectionState {
    case disconnected
    case scanning
    case connecting
    case connected
}

// MARK: - Discovered Device

struct DiscoveredDevice: Identifiable {
    let id: UUID
    let peripheral: CBPeripheral
    let name: String
    let rssi: Int
}

// MARK: - BLE Manager

class BLEManager: NSObject, ObservableObject {
    // Published state
    @Published var connectionState: ConnectionState = .disconnected
    @Published var discoveredDevices: [DiscoveredDevice] = []
    @Published var connectedDeviceName: String?
    @Published var lastStatusMessage: String?
    @Published var gpioState: GPIOState = GPIOState()

    // SECURITY: PIN verification state
    @Published var isAuthenticated: Bool = false
    @Published var needsPinVerification: Bool = false
    @Published var pinAttemptsRemaining: Int = 3
    @Published var showPinPrompt: Bool = false

    // Convenience computed properties
    var isConnected: Bool { connectionState == .connected }
    var isScanning: Bool { connectionState == .scanning }

    // CoreBluetooth
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var cmdCharacteristic: CBCharacteristic?
    private var respCharacteristic: CBCharacteristic?

    // Service and characteristic UUIDs
    private let serviceUUID = CBUUID(string: "F8B34000-6E8B-4B5A-9F3E-2C1D4A8E7F00")
    private let cmdCharUUID = CBUUID(string: "F8B34001-6E8B-4B5A-9F3E-2C1D4A8E7F00")
    private let respCharUUID = CBUUID(string: "F8B34002-6E8B-4B5A-9F3E-2C1D4A8E7F00")

    // Protocol handler
    private let protocol_ = HIDProtocol()

    // Queue for BLE operations
    private let bleQueue = DispatchQueue(label: "com.brewer.ble", qos: .userInteractive)

    // Pending name change (to update UI when confirmed)
    private var pendingDeviceName: String?

    // Advertised name from scan (use this instead of iOS cached name)
    private var advertisedDeviceName: String?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: bleQueue)
    }

    // MARK: - Scanning

    func startScanning() {
        guard centralManager.state == .poweredOn else {
            return
        }

        discoveredDevices.removeAll()
        DispatchQueue.main.async {
            self.connectionState = .scanning
        }

        centralManager.scanForPeripherals(
            withServices: [serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }

    func stopScanning() {
        centralManager.stopScan()
        DispatchQueue.main.async {
            if self.connectionState == .scanning {
                self.connectionState = .disconnected
            }
        }
    }

    // MARK: - Connection

    func connect(to device: DiscoveredDevice) {
        stopScanning()

        // Store the advertised name (not iOS cached name)
        advertisedDeviceName = device.name

        DispatchQueue.main.async {
            self.connectionState = .connecting
        }

        centralManager.connect(device.peripheral, options: nil)
    }

    func disconnect() {
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }

    // MARK: - Command Sending

    private func sendCommand(_ data: Data) {
        guard let characteristic = cmdCharacteristic,
              let peripheral = connectedPeripheral else {
            return
        }

        peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
    }

    // MARK: - Mouse Commands

    func sendMouseMove(dx: Int16, dy: Int16) {
        let data = protocol_.buildMouseMove(dx: dx, dy: dy)
        sendCommand(data)
    }

    func sendMouseClick(button: MouseButton) {
        let data = protocol_.buildMouseClick(button: button, action: .click)
        sendCommand(data)
    }

    func sendMouseScroll(vertical: Int8, horizontal: Int8) {
        let data = protocol_.buildMouseScroll(vertical: vertical, horizontal: horizontal)
        sendCommand(data)
    }

    func sendDragStart() {
        let data = protocol_.buildDragStart()
        sendCommand(data)
    }

    func sendDragEnd() {
        let data = protocol_.buildDragEnd()
        sendCommand(data)
    }

    // MARK: - Keyboard Commands

    func sendText(_ text: String) {
        let data = protocol_.buildKeyboardType(text: text, modifiers: [])
        sendCommand(data)
    }

    func sendSpecialKey(_ key: SpecialKey) {
        let data = protocol_.buildKeyboardKey(keycode: key.hidCode, modifiers: [], action: .tap)
        sendCommand(data)
    }

    func sendKeyCombo(modifiers: KeyModifier, key: KeyCode) {
        sendKeyCombo(modifiers: [modifiers], key: key)
    }

    func sendKeyCombo(modifiers: [KeyModifier], key: KeyCode) {
        let data = protocol_.buildKeyboardCombo(modifiers: modifiers, keycodes: [key.hidCode])
        sendCommand(data)
    }

    func sendMediaKey(_ key: MediaKey) {
        let data = protocol_.buildMediaKey(key: key, action: .tap)
        sendCommand(data)
    }

    // MARK: - Control Commands

    func sendPing() {
        let data = protocol_.buildPing()
        sendCommand(data)
    }

    func requestDeviceInfo() {
        let data = protocol_.buildGetInfo()
        sendCommand(data)
    }

    // MARK: - Configuration Commands

    func setDeviceName(_ name: String) {
        guard !name.isEmpty, name.count <= 20 else {
            return
        }
        pendingDeviceName = name
        let data = protocol_.buildSetName(name: name)
        sendCommand(data)
    }

    func setPin(_ pin: String) {
        guard pin.count >= 4, pin.count <= 8 else {
            return
        }
        guard pin.allSatisfy({ $0.isNumber }) else {
            return
        }
        let data = protocol_.buildSetPin(pin: pin)
        sendCommand(data)
    }

    func clearPin() {
        let data = protocol_.buildClearPin()
        sendCommand(data)
    }

    func verifyPin(_ pin: String) {
        let data = protocol_.buildVerifyPin(pin: pin)
        sendCommand(data)
    }

    func requestDeviceName() {
        let data = protocol_.buildGetName()
        sendCommand(data)
    }

    // MARK: - GPIO Commands

    /// Set a single LED state
    func setLed(_ index: Int, on: Bool) {
        guard index >= 0 && index < 3 else { return }
        let data = protocol_.buildSetLed(index: UInt8(index), state: on ? 1 : 0)
        sendCommand(data)
    }

    /// Set all LEDs at once using a bitmask
    func setAllLeds(_ bitmask: UInt8) {
        let data = protocol_.buildSetLed(index: 0xFF, state: bitmask)
        sendCommand(data)
    }

    /// Set a single relay state
    func setRelay(_ index: Int, on: Bool) {
        guard index >= 0 && index < 7 else { return }
        let data = protocol_.buildSetRelay(index: UInt8(index), state: on ? 1 : 0)
        sendCommand(data)
    }

    /// Set all relays at once using a bitmask
    func setAllRelays(_ bitmask: UInt8) {
        let data = protocol_.buildSetRelay(index: 0xFF, state: bitmask)
        sendCommand(data)
    }

    /// Request current GPIO state from device
    func requestGpioState() {
        let data = protocol_.buildGetGpioState()
        sendCommand(data)
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            break
        case .poweredOff:
            DispatchQueue.main.async {
                self.connectionState = .disconnected
            }
        default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        // Prefer advertised name (current) over peripheral.name (iOS cached)
        let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? peripheral.name ?? "Unknown"

        let device = DiscoveredDevice(
            id: peripheral.identifier,
            peripheral: peripheral,
            name: name,
            rssi: RSSI.intValue
        )

        DispatchQueue.main.async {
            // Update existing or add new
            if let index = self.discoveredDevices.firstIndex(where: { $0.id == device.id }) {
                self.discoveredDevices[index] = device
            } else {
                self.discoveredDevices.append(device)
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        peripheral.delegate = self

        DispatchQueue.main.async {
            // Use advertised name (from scan), not iOS cached peripheral.name
            self.connectedDeviceName = self.advertisedDeviceName ?? peripheral.name
            self.connectionState = .connected
        }

        // Discover services
        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        DispatchQueue.main.async {
            self.connectionState = .disconnected
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        connectedPeripheral = nil
        cmdCharacteristic = nil
        respCharacteristic = nil

        DispatchQueue.main.async {
            self.connectedDeviceName = nil
            self.connectionState = .disconnected
            // SECURITY: Reset auth state on disconnect
            self.isAuthenticated = false
            self.needsPinVerification = false
            self.showPinPrompt = false
            self.pinAttemptsRemaining = 3
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil, let services = peripheral.services else { return }

        for service in services {
            if service.uuid == serviceUUID {
                peripheral.discoverCharacteristics([cmdCharUUID, respCharUUID], for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard error == nil, let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            switch characteristic.uuid {
            case cmdCharUUID:
                cmdCharacteristic = characteristic

            case respCharUUID:
                respCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)

            default:
                break
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard error == nil else { return }

        if characteristic.uuid == respCharUUID && characteristic.isNotifying {
            // Request device name from firmware to get the real name (not iOS cached)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.requestDeviceName()
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard error == nil, let data = characteristic.value else { return }

        // Check for name response - update connected device name
        if data.count >= 3 && data[0] == CommandType.nameResponse.rawValue {
            let nameLen = Int(data[2])
            if data.count >= 3 + nameLen {
                let nameData = data.subdata(in: 3..<(3 + nameLen))
                if let name = String(data: nameData, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self.connectedDeviceName = name
                    }
                }
            }
        }

        // Check for PIN result response
        if data.count >= 4 && data[0] == CommandType.pinResult.rawValue {
            let success = data[2] != 0
            let attemptsLeft = Int(data[3])

            DispatchQueue.main.async {
                self.pinAttemptsRemaining = attemptsLeft
                if success {
                    self.isAuthenticated = true
                    self.needsPinVerification = false
                    self.showPinPrompt = false
                } else {
                    self.isAuthenticated = false
                }
            }
        }

        // Check for successful name change (status response for setName command)
        if data.count >= 4 && data[0] == CommandType.status.rawValue {
            let statusCode = data[2]
            let originalCmd = data[3]

            // SECURITY: Check for auth required error (0x03)
            if statusCode == 0x03 {
                DispatchQueue.main.async {
                    self.needsPinVerification = true
                    self.showPinPrompt = true
                    self.isAuthenticated = false
                }
            }

            // If setName command succeeded (status OK = 0x00)
            if originalCmd == CommandType.setName.rawValue {
                if statusCode == 0x00 {
                    if let newName = pendingDeviceName {
                        DispatchQueue.main.async {
                            self.connectedDeviceName = newName
                        }
                        pendingDeviceName = nil
                    }
                } else {
                    pendingDeviceName = nil
                }
            }

            // After GPIO set commands, refresh GPIO state
            if originalCmd == CommandType.gpioSetLed.rawValue ||
               originalCmd == CommandType.gpioSetRelay.rawValue {
                if statusCode == 0x00 {
                    // Request updated GPIO state after successful change
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.requestGpioState()
                    }
                }
            }
        }

        // Check for GPIO state response
        if data[0] == CommandType.gpioState.rawValue {
            if let state = protocol_.parseGpioState(data) {
                DispatchQueue.main.async {
                    self.gpioState = state
                }
            }
        }

        // Parse response
        if let response = protocol_.parseResponse(data) {
            DispatchQueue.main.async {
                self.lastStatusMessage = response
            }
        }
    }
}
