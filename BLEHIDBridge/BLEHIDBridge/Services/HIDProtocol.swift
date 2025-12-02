/*
 * HID-HOP - HID Protocol
 *
 * Binary protocol implementation matching the firmware protocol.h
 */

import Foundation

// MARK: - Command Types

enum CommandType: UInt8 {
    // Mouse commands
    case mouseMove = 0x01
    case mouseClick = 0x02
    case mouseScroll = 0x03
    case mouseDragStart = 0x04
    case mouseDragEnd = 0x05

    // Keyboard commands
    case keyboardType = 0x20
    case keyboardKey = 0x21
    case keyboardCombo = 0x22
    case keyboardSpecial = 0x23
    case mediaKey = 0x24

    // Control commands
    case ping = 0x40
    case pong = 0x41
    case getInfo = 0x42
    case infoResponse = 0x43
    case setConfig = 0x44
    case reset = 0x45
    case setName = 0x46
    case getName = 0x4A
    case nameResponse = 0x4B
    case setPin = 0x47
    case verifyPin = 0x48
    case pinResult = 0x49

    // Security commands
    case authChallenge = 0x60
    case authResponse = 0x61
    case sessionStart = 0x62
    case sessionEnd = 0x63

    // GPIO commands
    case gpioSetLed = 0x80
    case gpioGetLed = 0x81
    case gpioSetRelay = 0x82
    case gpioGetRelay = 0x83
    case gpioReadDin = 0x84
    case gpioReadAin = 0x85
    case gpioGetAll = 0x86
    case gpioState = 0x87

    // Status
    case status = 0xE0
    case error = 0xFF
}

// MARK: - Mouse Types

enum MouseButton: UInt8 {
    case left = 0x01
    case right = 0x02
    case middle = 0x04
}

enum MouseAction: UInt8 {
    case release = 0
    case press = 1
    case click = 2
}

// MARK: - Keyboard Types

enum KeyModifier: UInt8 {
    case none = 0x00
    case leftCtrl = 0x01
    case leftShift = 0x02
    case leftAlt = 0x04
    case gui = 0x08  // Command on Mac
    case rightCtrl = 0x10
    case rightShift = 0x20
    case rightAlt = 0x40
    case rightGui = 0x80

    // Convenience aliases
    static let ctrl = leftCtrl
    static let shift = leftShift
    static let alt = leftAlt
    static let cmd = gui
}

enum KeyAction: UInt8 {
    case release = 0
    case press = 1
    case tap = 2
}

// MARK: - Special Keys

enum SpecialKey {
    case escape
    case backspace
    case tab
    case enter
    case delete
    case home
    case end
    case pageUp
    case pageDown
    case arrowUp
    case arrowDown
    case arrowLeft
    case arrowRight

    var hidCode: UInt8 {
        switch self {
        case .escape: return 0x29
        case .backspace: return 0x2A
        case .tab: return 0x2B
        case .enter: return 0x28
        case .delete: return 0x4C
        case .home: return 0x4A
        case .end: return 0x4D
        case .pageUp: return 0x4B
        case .pageDown: return 0x4E
        case .arrowUp: return 0x52
        case .arrowDown: return 0x51
        case .arrowLeft: return 0x50
        case .arrowRight: return 0x4F
        }
    }
}

// MARK: - Key Codes

enum KeyCode {
    case a, b, c, d, e, f, g, h, i, j, k, l, m
    case n, o, p, q, r, s, t, u, v, w, x, y, z
    case one, two, three, four, five, six, seven, eight, nine, zero
    case space, tab, enter
    case leftBracket, rightBracket
    case arrowUp, arrowDown, arrowLeft, arrowRight

    var hidCode: UInt8 {
        switch self {
        case .a: return 0x04
        case .b: return 0x05
        case .c: return 0x06
        case .d: return 0x07
        case .e: return 0x08
        case .f: return 0x09
        case .g: return 0x0A
        case .h: return 0x0B
        case .i: return 0x0C
        case .j: return 0x0D
        case .k: return 0x0E
        case .l: return 0x0F
        case .m: return 0x10
        case .n: return 0x11
        case .o: return 0x12
        case .p: return 0x13
        case .q: return 0x14
        case .r: return 0x15
        case .s: return 0x16
        case .t: return 0x17
        case .u: return 0x18
        case .v: return 0x19
        case .w: return 0x1A
        case .x: return 0x1B
        case .y: return 0x1C
        case .z: return 0x1D
        case .one: return 0x1E
        case .two: return 0x1F
        case .three: return 0x20
        case .four: return 0x21
        case .five: return 0x22
        case .six: return 0x23
        case .seven: return 0x24
        case .eight: return 0x25
        case .nine: return 0x26
        case .zero: return 0x27
        case .space: return 0x2C
        case .tab: return 0x2B
        case .enter: return 0x28
        case .leftBracket: return 0x2F
        case .rightBracket: return 0x30
        case .arrowUp: return 0x52
        case .arrowDown: return 0x51
        case .arrowLeft: return 0x50
        case .arrowRight: return 0x4F
        }
    }
}

// MARK: - Media Keys (Consumer Control Usage IDs)

enum MediaKey: UInt16 {
    case playPause     = 0x00CD
    case nextTrack     = 0x00B5
    case previousTrack = 0x00B6
    case stop          = 0x00B7
    case volumeUp      = 0x00E9
    case volumeDown    = 0x00EA
    case mute          = 0x00E2
    case brightnessUp  = 0x006F
    case brightnessDown = 0x0070
    case eject         = 0x00B8
}

enum MediaKeyAction: UInt8 {
    case release = 0
    case press = 1
    case tap = 2
}

// MARK: - Status Codes

enum StatusCode: UInt8 {
    case ok = 0x00
    case unknownCmd = 0x01
    case invalidLen = 0x02
    case authRequired = 0x03
    case usbBusy = 0x04
    case usbFailed = 0x05
    case invalidData = 0x06

    var description: String {
        switch self {
        case .ok: return "OK"
        case .unknownCmd: return "Unknown command"
        case .invalidLen: return "Invalid length"
        case .authRequired: return "Authentication required"
        case .usbBusy: return "USB busy"
        case .usbFailed: return "USB failed"
        case .invalidData: return "Invalid data"
        }
    }
}

// MARK: - GPIO State

struct GPIOState {
    var ledState: UInt8 = 0       // Bitmask: LED0=bit0, LED1=bit1, LED2=bit2
    var relayState: UInt8 = 0     // Bitmask: Relay0-6 = bits 0-6
    var dinState: UInt8 = 0       // Bitmask: DIN0=bit0, DIN1=bit1
    var ain0Value: UInt16 = 0     // 12-bit ADC value (0-4095)
    var ain1Value: UInt16 = 0     // 12-bit ADC value (0-4095)

    // LED accessors
    func ledOn(_ index: Int) -> Bool {
        return (ledState & (1 << index)) != 0
    }

    // Relay accessors
    func relayOn(_ index: Int) -> Bool {
        return (relayState & (1 << index)) != 0
    }

    // Digital input accessors
    func dinActive(_ index: Int) -> Bool {
        return (dinState & (1 << index)) != 0
    }

    // Analog input voltage (assuming 3.3V reference, 1/6 gain)
    func ainVoltage(_ index: Int) -> Double {
        let value = index == 0 ? ain0Value : ain1Value
        // With 1/6 gain and internal reference (0.6V), full scale is 3.6V
        return (Double(value) / 4095.0) * 3.6
    }
}

// MARK: - Protocol Implementation

class HIDProtocol {

    // MARK: - Header Building

    private func buildHeader(type: CommandType, payloadLength: UInt8) -> Data {
        return Data([type.rawValue, payloadLength])
    }

    // MARK: - Mouse Commands

    func buildMouseMove(dx: Int16, dy: Int16) -> Data {
        var data = buildHeader(type: .mouseMove, payloadLength: 4)
        withUnsafeBytes(of: dx.littleEndian) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: dy.littleEndian) { data.append(contentsOf: $0) }
        return data
    }

    func buildMouseClick(button: MouseButton, action: MouseAction) -> Data {
        var data = buildHeader(type: .mouseClick, payloadLength: 2)
        data.append(button.rawValue)
        data.append(action.rawValue)
        return data
    }

    func buildMouseScroll(vertical: Int8, horizontal: Int8) -> Data {
        var data = buildHeader(type: .mouseScroll, payloadLength: 2)
        data.append(UInt8(bitPattern: vertical))
        data.append(UInt8(bitPattern: horizontal))
        return data
    }

    func buildDragStart() -> Data {
        return buildHeader(type: .mouseDragStart, payloadLength: 0)
    }

    func buildDragEnd() -> Data {
        return buildHeader(type: .mouseDragEnd, payloadLength: 0)
    }

    // MARK: - Keyboard Commands

    func buildKeyboardType(text: String, modifiers: [KeyModifier]) -> Data {
        let textData = text.data(using: .utf8) ?? Data()
        let textLength = min(textData.count, 64)

        var data = buildHeader(type: .keyboardType, payloadLength: UInt8(2 + textLength))

        // Combine modifiers
        let modValue = modifiers.reduce(UInt8(0)) { $0 | $1.rawValue }
        data.append(modValue)
        data.append(UInt8(textLength))
        data.append(textData.prefix(textLength))

        return data
    }

    func buildKeyboardKey(keycode: UInt8, modifiers: [KeyModifier], action: KeyAction) -> Data {
        var data = buildHeader(type: .keyboardKey, payloadLength: 3)

        let modValue = modifiers.reduce(UInt8(0)) { $0 | $1.rawValue }
        data.append(modValue)
        data.append(keycode)
        data.append(action.rawValue)

        return data
    }

    func buildKeyboardCombo(modifiers: [KeyModifier], keycodes: [UInt8]) -> Data {
        let keyCount = min(keycodes.count, 6)
        var data = buildHeader(type: .keyboardCombo, payloadLength: UInt8(2 + keyCount))

        let modValue = modifiers.reduce(UInt8(0)) { $0 | $1.rawValue }
        data.append(modValue)
        data.append(UInt8(keyCount))
        for i in 0..<keyCount {
            data.append(keycodes[i])
        }

        return data
    }

    // MARK: - Media Key Commands

    func buildMediaKey(key: MediaKey, action: MediaKeyAction = .tap) -> Data {
        var data = buildHeader(type: .mediaKey, payloadLength: 3)

        // Usage ID as 16-bit little-endian
        withUnsafeBytes(of: key.rawValue.littleEndian) { data.append(contentsOf: $0) }
        data.append(action.rawValue)

        return data
    }

    // MARK: - Control Commands

    func buildPing() -> Data {
        var data = buildHeader(type: .ping, payloadLength: 8)

        // Use truncated timestamp (wraps every ~49 days, but fine for ping)
        let timestamp = UInt32(truncatingIfNeeded: UInt64(Date().timeIntervalSince1970 * 1000))
        let sequence = UInt32.random(in: 0...UInt32.max)

        withUnsafeBytes(of: timestamp.littleEndian) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: sequence.littleEndian) { data.append(contentsOf: $0) }

        return data
    }

    func buildGetInfo() -> Data {
        return buildHeader(type: .getInfo, payloadLength: 0)
    }

    // MARK: - Configuration Commands

    func buildSetName(name: String) -> Data {
        let nameData = name.data(using: .utf8) ?? Data()
        let nameLength = min(nameData.count, 20)  // MAX_DEVICE_NAME_LENGTH

        var data = buildHeader(type: .setName, payloadLength: UInt8(1 + nameLength))
        data.append(UInt8(nameLength))
        data.append(nameData.prefix(nameLength))

        return data
    }

    func buildGetName() -> Data {
        return buildHeader(type: .getName, payloadLength: 0)
    }

    func buildSetPin(pin: String) -> Data {
        let pinData = pin.data(using: .utf8) ?? Data()
        let pinLength = min(pinData.count, 8)  // MAX_PIN_LENGTH

        var data = buildHeader(type: .setPin, payloadLength: UInt8(1 + pinLength))
        data.append(UInt8(pinLength))
        data.append(pinData.prefix(pinLength))

        return data
    }

    func buildClearPin() -> Data {
        var data = buildHeader(type: .setPin, payloadLength: 1)
        data.append(0)  // length = 0 means clear PIN
        return data
    }

    func buildVerifyPin(pin: String) -> Data {
        let pinData = pin.data(using: .utf8) ?? Data()
        let pinLength = min(pinData.count, 8)

        var data = buildHeader(type: .verifyPin, payloadLength: UInt8(1 + pinLength))
        data.append(UInt8(pinLength))
        data.append(pinData.prefix(pinLength))

        return data
    }

    // MARK: - GPIO Commands

    /// Set a single LED (index 0-2) or all LEDs (index 0xFF with bitmask)
    func buildSetLed(index: UInt8, state: UInt8) -> Data {
        var data = buildHeader(type: .gpioSetLed, payloadLength: 2)
        data.append(index)
        data.append(state)
        return data
    }

    /// Set a single relay (index 0-6) or all relays (index 0xFF with bitmask)
    func buildSetRelay(index: UInt8, state: UInt8) -> Data {
        var data = buildHeader(type: .gpioSetRelay, payloadLength: 2)
        data.append(index)
        data.append(state)
        return data
    }

    /// Request all GPIO state
    func buildGetGpioState() -> Data {
        return buildHeader(type: .gpioGetAll, payloadLength: 0)
    }

    /// Request LED state only
    func buildGetLedState() -> Data {
        return buildHeader(type: .gpioGetLed, payloadLength: 0)
    }

    /// Request relay state only
    func buildGetRelayState() -> Data {
        return buildHeader(type: .gpioGetRelay, payloadLength: 0)
    }

    /// Request digital input state
    func buildReadDigitalInputs() -> Data {
        return buildHeader(type: .gpioReadDin, payloadLength: 0)
    }

    /// Request analog input values
    func buildReadAnalogInputs() -> Data {
        return buildHeader(type: .gpioReadAin, payloadLength: 0)
    }

    // MARK: - Response Parsing

    func parseResponse(_ data: Data) -> String? {
        guard data.count >= 2 else { return nil }

        let type = data[0]
        let length = data[1]

        guard data.count >= Int(length) + 2 else { return nil }

        switch type {
        case CommandType.status.rawValue:
            guard data.count >= 4 else { return nil }
            let statusCode = StatusCode(rawValue: data[2]) ?? .unknownCmd
            let originalCmd = data[3]
            let cmdName = commandName(for: originalCmd)
            return "\(cmdName): \(statusCode.description)"

        case CommandType.pong.rawValue:
            return "Pong received"

        case CommandType.infoResponse.rawValue:
            guard data.count >= 10 else { return nil }
            let vMajor = data[2]
            let vMinor = data[3]
            let usbConnected = data[4] != 0
            let sessionActive = data[5] != 0
            let uptime = UInt32(data[6]) | (UInt32(data[7]) << 8) |
                         (UInt32(data[8]) << 16) | (UInt32(data[9]) << 24)
            return "Version \(vMajor).\(vMinor), USB: \(usbConnected), Session: \(sessionActive), Uptime: \(uptime)s"

        case CommandType.pinResult.rawValue:
            guard data.count >= 4 else { return nil }
            let success = data[2] != 0
            let attemptsLeft = data[3]
            if success {
                return "PIN verified successfully"
            } else {
                return "PIN incorrect, \(attemptsLeft) attempts remaining"
            }

        case CommandType.nameResponse.rawValue:
            guard data.count >= 3 else { return nil }
            let nameLen = Int(data[2])
            guard data.count >= 3 + nameLen else { return nil }
            let nameData = data.subdata(in: 3..<(3 + nameLen))
            let name = String(data: nameData, encoding: .utf8) ?? "?"
            return "Device name: \(name)"

        case CommandType.gpioState.rawValue:
            guard data.count >= 9 else { return nil }  // 2 header + 7 payload
            let ledState = data[2]
            let relayState = data[3]
            let dinState = data[4]
            let ain0 = UInt16(data[5]) | (UInt16(data[6]) << 8)
            let ain1 = UInt16(data[7]) | (UInt16(data[8]) << 8)
            return "GPIO: LEDs=0x\(String(format: "%02X", ledState)), Relays=0x\(String(format: "%02X", relayState)), DIN=0x\(String(format: "%02X", dinState)), AIN0=\(ain0), AIN1=\(ain1)"

        default:
            return "Unknown response: 0x\(String(format: "%02X", type))"
        }
    }

    /// Parse GPIO state response into GPIOState struct
    func parseGpioState(_ data: Data) -> GPIOState? {
        guard data.count >= 9,
              data[0] == CommandType.gpioState.rawValue else {
            return nil
        }

        var state = GPIOState()
        state.ledState = data[2]
        state.relayState = data[3]
        state.dinState = data[4]
        state.ain0Value = UInt16(data[5]) | (UInt16(data[6]) << 8)
        state.ain1Value = UInt16(data[7]) | (UInt16(data[8]) << 8)
        return state
    }

    private func commandName(for cmd: UInt8) -> String {
        switch cmd {
        case CommandType.mouseMove.rawValue: return "Mouse Move"
        case CommandType.mouseClick.rawValue: return "Mouse Click"
        case CommandType.mouseScroll.rawValue: return "Mouse Scroll"
        case CommandType.keyboardType.rawValue: return "Keyboard Type"
        case CommandType.keyboardKey.rawValue: return "Keyboard Key"
        case CommandType.mediaKey.rawValue: return "Media Key"
        case CommandType.setName.rawValue: return "Set Name"
        case CommandType.setPin.rawValue: return "Set PIN"
        case CommandType.verifyPin.rawValue: return "Verify PIN"
        case CommandType.ping.rawValue: return "Ping"
        case CommandType.getInfo.rawValue: return "Get Info"
        case CommandType.gpioSetLed.rawValue: return "Set LED"
        case CommandType.gpioSetRelay.rawValue: return "Set Relay"
        case CommandType.gpioGetAll.rawValue: return "Get GPIO"
        default: return "Command 0x\(String(format: "%02X", cmd))"
        }
    }
}
