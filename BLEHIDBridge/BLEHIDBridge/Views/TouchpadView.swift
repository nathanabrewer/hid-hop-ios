/*
 * HID-HOP - Touchpad View with QWERTY Keyboard
 * Where fingers meet the beat
 */

import SwiftUI
import UIKit

struct TouchpadView: View {
    @EnvironmentObject var bleManager: BLEManager
    @State private var shiftActive = false
    @State private var capsLock = false
    @State private var showNumbers = false
    @State private var isDragging = false
    @State private var isTouchingPad = false

    // Sensitivity settings
    @AppStorage("touchpadSensitivity") private var sensitivity: Double = 1.5
    @AppStorage("scrollSensitivity") private var scrollSensitivity: Double = 1.0

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 8) {
                // Touchpad area with natural drag support
                NaturalTouchpad(
                    sensitivity: sensitivity,
                    isDragging: $isDragging,
                    isTouching: $isTouchingPad,
                    onMove: { dx, dy in
                        let scaledDx = Int16(dx * sensitivity)
                        let scaledDy = Int16(dy * sensitivity)
                        bleManager.sendMouseMove(dx: scaledDx, dy: scaledDy)
                    },
                    onTap: {
                        bleManager.sendMouseClick(button: .left)
                    },
                    onDoubleTap: {
                        bleManager.sendMouseClick(button: .left)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            bleManager.sendMouseClick(button: .left)
                        }
                    },
                    onTwoFingerTap: {
                        bleManager.sendMouseClick(button: .right)
                    },
                    onDragStart: {
                        bleManager.sendDragStart()
                    },
                    onDragEnd: {
                        bleManager.sendDragEnd()
                    },
                    onScroll: { dy in
                        let scaledV = Int8(clamping: Int(-dy * scrollSensitivity))
                        bleManager.sendMouseScroll(vertical: scaledV, horizontal: 0)
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Mouse buttons with scroll wheel in center
                HStack(spacing: 12) {
                    // Left click
                    MouseButtonView(title: "Left", action: {
                        bleManager.sendMouseClick(button: .left)
                    })

                    // Scroll wheel in center
                    ScrollWheelView(
                        onScroll: { delta in
                            let scaledV = Int8(clamping: Int(delta * scrollSensitivity))
                            bleManager.sendMouseScroll(vertical: scaledV, horizontal: 0)
                        },
                        onTap: {
                            bleManager.sendMouseClick(button: .middle)
                        }
                    )
                    .frame(width: 70, height: 50)

                    // Right click
                    MouseButtonView(title: "Right", action: {
                        bleManager.sendMouseClick(button: .right)
                    })
                }
                .frame(height: 50)
                .padding(.horizontal)

                // Full QWERTY Keyboard
                QWERTYKeyboardView(
                    shiftActive: $shiftActive,
                    capsLock: $capsLock,
                    showNumbers: $showNumbers,
                    onKey: { key in
                        bleManager.sendText(key)
                    },
                    onSpecialKey: { key in
                        bleManager.sendSpecialKey(key)
                    },
                    onModifierCombo: { modifiers, keyCode in
                        bleManager.sendKeyCombo(modifiers: modifiers, key: keyCode)
                    },
                    onPassword: { password in
                        bleManager.sendText(password)
                    }
                )
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Scroll Wheel View

struct ScrollWheelView: View {
    let onScroll: (CGFloat) -> Void
    let onTap: () -> Void

    @State private var lastY: CGFloat?
    @State private var scrollAccumulator: CGFloat = 0
    @State private var rotation: Double = 0
    @GestureState private var isDragging = false

    private let scrollThreshold: CGFloat = 8  // Pixels per scroll notch
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        ZStack {
            // Wheel background
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color(.systemGray4), Color(.systemGray5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.hopCyan.opacity(0.5), .hopPurple.opacity(0.5)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )

            // Wheel texture (horizontal lines to indicate scrolling)
            VStack(spacing: 4) {
                ForEach(0..<5) { i in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(
                            LinearGradient(
                                colors: [.hopCyan.opacity(0.3), .hopPurple.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 2)
                        .padding(.horizontal, 12)
                }
            }
            .rotationEffect(.degrees(rotation))

            // Center dot (middle click indicator)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.hopCyan.opacity(0.6), .hopPurple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 16, height: 16)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($isDragging) { _, state, _ in
                    state = true
                }
                .onChanged { value in
                    if let last = lastY {
                        let delta = value.location.y - last
                        scrollAccumulator += delta

                        // Visual rotation feedback
                        rotation = delta * 2

                        // Check if we've crossed a scroll threshold
                        while abs(scrollAccumulator) >= scrollThreshold {
                            let direction: CGFloat = scrollAccumulator > 0 ? -1 : 1
                            onScroll(direction)
                            hapticFeedback.impactOccurred()
                            scrollAccumulator -= (scrollAccumulator > 0 ? scrollThreshold : -scrollThreshold)
                        }
                    }
                    lastY = value.location.y
                }
                .onEnded { _ in
                    lastY = nil
                    scrollAccumulator = 0
                    withAnimation(.spring(response: 0.2)) {
                        rotation = 0
                    }
                }
        )
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    onTap()
                    hapticFeedback.impactOccurred(intensity: 0.8)
                }
        )
        .onAppear {
            hapticFeedback.prepare()
        }
    }
}

// MARK: - QWERTY Keyboard View

struct QWERTYKeyboardView: View {
    @Binding var shiftActive: Bool
    @Binding var capsLock: Bool
    @Binding var showNumbers: Bool
    @State private var showPasswordAutofill = false

    let onKey: (String) -> Void
    let onSpecialKey: (SpecialKey) -> Void
    let onModifierCombo: ([KeyModifier], KeyCode) -> Void
    let onPassword: (String) -> Void

    private let hapticFeedback = UIImpactFeedbackGenerator(style: .light)

    // Keyboard layouts
    private let letterRow1 = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]
    private let letterRow2 = ["A", "S", "D", "F", "G", "H", "J", "K", "L"]
    private let letterRow3 = ["Z", "X", "C", "V", "B", "N", "M"]

    private let numberRow1 = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
    private let symbolRow1 = ["!", "@", "#", "$", "%", "^", "&", "*", "(", ")"]
    private let symbolRow2 = ["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""]
    private let symbolRow3 = [".", ",", "?", "!", "'"]

    var body: some View {
        VStack(spacing: 6) {
            // Row 1: Numbers/Symbols or QWERTYUIOP
            HStack(spacing: 4) {
                ForEach(showNumbers ? (shiftActive ? symbolRow1 : numberRow1) : letterRow1, id: \.self) { key in
                    KeyButton(
                        label: displayKey(key),
                        width: .flexible,
                        action: { tapKey(key) }
                    )
                }
            }

            // Row 2: ASDFGHJKL or symbols
            HStack(spacing: 4) {
                if showNumbers {
                    ForEach(shiftActive ? symbolRow2 : symbolRow2, id: \.self) { key in
                        KeyButton(
                            label: key,
                            width: .flexible,
                            action: { tapKey(key) }
                        )
                    }
                } else {
                    Spacer().frame(width: 16)
                    ForEach(letterRow2, id: \.self) { key in
                        KeyButton(
                            label: displayKey(key),
                            width: .flexible,
                            action: { tapKey(key) }
                        )
                    }
                    Spacer().frame(width: 16)
                }
            }

            // Row 3: Shift + ZXCVBNM + Backspace
            HStack(spacing: 4) {
                // Shift key
                KeyButton(
                    label: shiftActive || capsLock ? "⬆︎" : "⇧",
                    width: .fixed(44),
                    isActive: shiftActive || capsLock,
                    action: {
                        shiftActive.toggle()
                    },
                    onLongPress: {
                        capsLock.toggle()
                        shiftActive = capsLock
                    }
                )

                if showNumbers {
                    ForEach(symbolRow3, id: \.self) { key in
                        KeyButton(
                            label: key,
                            width: .flexible,
                            action: { tapKey(key) }
                        )
                    }
                } else {
                    ForEach(letterRow3, id: \.self) { key in
                        KeyButton(
                            label: displayKey(key),
                            width: .flexible,
                            action: { tapKey(key) }
                        )
                    }
                }

                // Backspace
                KeyButton(
                    label: "⌫",
                    width: .fixed(44),
                    action: { onSpecialKey(.backspace) }
                )
            }

            // Row 4: Number toggle, password, space, enter
            HStack(spacing: 4) {
                // Number/Symbol toggle
                KeyButton(
                    label: showNumbers ? "ABC" : "123",
                    width: .fixed(44),
                    isActive: showNumbers,
                    action: {
                        showNumbers.toggle()
                    }
                )

                // Password autofill button
                KeyButton(
                    label: "🔑",
                    width: .fixed(40),
                    color: .hopGold.opacity(0.8),
                    action: {
                        hapticFeedback.impactOccurred()
                        showPasswordAutofill = true
                    }
                )

                // Space bar
                KeyButton(
                    label: "space",
                    width: .flexible,
                    action: { tapKey(" ") }
                )

                // Enter
                KeyButton(
                    label: "⏎",
                    width: .fixed(50),
                    color: .hopPurple,
                    action: { onSpecialKey(.enter) }
                )
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [.hopPurple.opacity(0.2), .hopPink.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .sheet(isPresented: $showPasswordAutofill) {
            PasswordAutofillView { password in
                showPasswordAutofill = false
                if !password.isEmpty {
                    onPassword(password)
                }
            }
        }
    }

    private func displayKey(_ key: String) -> String {
        if shiftActive || capsLock {
            return key.uppercased()
        }
        return key.lowercased()
    }

    private func tapKey(_ key: String) {
        hapticFeedback.impactOccurred()

        let output: String
        if shiftActive || capsLock {
            output = key.uppercased()
        } else {
            output = key.lowercased()
        }

        onKey(output)

        // Turn off shift after typing (unless caps lock is on)
        if shiftActive && !capsLock {
            shiftActive = false
        }
    }
}

// MARK: - Key Button

enum KeyWidth {
    case flexible
    case fixed(CGFloat)
}

struct KeyButton: View {
    let label: String
    var width: KeyWidth = .flexible
    var isActive: Bool = false
    var color: Color = Color(.systemGray4)
    let action: () -> Void
    var onLongPress: (() -> Void)? = nil

    @State private var isPressed = false

    var body: some View {
        let baseView = Text(label)
            .font(.system(size: label.count > 2 ? 12 : 18, weight: .medium))
            .foregroundColor(isActive ? .white : .primary)
            .frame(height: 42)
            .frame(maxWidth: widthValue)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isActive ? Color.blue : (isPressed ? color.opacity(0.6) : color))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.gray.opacity(0.2), lineWidth: 0.5)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)

        Group {
            if let longPress = onLongPress {
                baseView
                    .onTapGesture {
                        action()
                    }
                    .onLongPressGesture(minimumDuration: 0.5) {
                        longPress()
                    } onPressingChanged: { pressing in
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isPressed = pressing
                        }
                    }
            } else {
                Button(action: action) {
                    baseView
                }
                .buttonStyle(PlainButtonStyle())
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isPressed {
                                withAnimation(.easeInOut(duration: 0.05)) {
                                    isPressed = true
                                }
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.easeInOut(duration: 0.1)) {
                                isPressed = false
                            }
                        }
                )
            }
        }
    }

    private var widthValue: CGFloat? {
        switch width {
        case .flexible:
            return .infinity
        case .fixed(let value):
            return value
        }
    }
}

// MARK: - Natural Touchpad with Tap-Hold-Drag

struct NaturalTouchpad: UIViewRepresentable {
    let sensitivity: Double
    @Binding var isDragging: Bool
    @Binding var isTouching: Bool

    let onMove: (CGFloat, CGFloat) -> Void
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    let onTwoFingerTap: () -> Void
    let onDragStart: () -> Void
    let onDragEnd: () -> Void
    let onScroll: (CGFloat) -> Void

    func makeUIView(context: Context) -> TouchpadUIView {
        let view = TouchpadUIView()
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ uiView: TouchpadUIView, context: Context) {
        uiView.coordinator = context.coordinator
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator {
        var parent: NaturalTouchpad

        init(_ parent: NaturalTouchpad) {
            self.parent = parent
        }
    }
}

class TouchpadUIView: UIView {
    weak var coordinator: NaturalTouchpad.Coordinator?

    // Touch state
    private var lastLocation: CGPoint?
    private var touchDownTime: Date?
    private var touchStartLocation: CGPoint?
    private var isDragging = false
    private var hasMoved = false
    private var totalMovement: CGFloat = 0

    // Two-finger tracking
    private var initialTwoFingerDistance: CGFloat?
    private var lastTwoFingerCenter: CGPoint?

    // Timing thresholds
    private let tapThreshold: TimeInterval = 0.2      // Max time for a tap
    private let moveThreshold: CGFloat = 10           // Pixels before considered a move (not tap)
    private let doubleTapInterval: TimeInterval = 0.3 // Window for double-tap click
    private let doubleTapDragWindow: TimeInterval = 0.25  // Tighter window for drag initiation
    private let dragTapProximity: CGFloat = 30        // Must be close to original tap

    // Double-tap-to-drag detection
    private var lastTapTime: Date?
    private var lastTapLocation: CGPoint?
    private var potentialDragStart = false  // True if this touch could be a drag (after recent tap)

    // Haptics
    private let hapticLight = UIImpactFeedbackGenerator(style: .light)
    private let hapticMedium = UIImpactFeedbackGenerator(style: .medium)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear
        isMultipleTouchEnabled = true
        hapticLight.prepare()
        hapticMedium.prepare()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        // Draw rounded rectangle background
        let path = UIBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), cornerRadius: 20)

        // Gradient fill
        let colors = [UIColor.systemGray5.cgColor, UIColor.systemGray6.cgColor]
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1])!

        context.saveGState()
        path.addClip()
        context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: bounds.width, y: bounds.height), options: [])
        context.restoreGState()

        // Border
        let borderColor: UIColor = isDragging ? .systemOrange : .systemPurple.withAlphaComponent(0.3)
        borderColor.setStroke()
        path.lineWidth = isDragging ? 3 : 1
        path.stroke()

        // Center icon and text
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let iconAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 32),
            .foregroundColor: UIColor.systemPurple.withAlphaComponent(0.3)
        ]

        let textAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.preferredFont(forTextStyle: .caption2),
            .foregroundColor: UIColor.secondaryLabel,
            .paragraphStyle: paragraphStyle
        ]

        if isDragging {
            let dragText = "DRAGGING"
            let dragAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                .foregroundColor: UIColor.systemOrange,
                .paragraphStyle: paragraphStyle
            ]
            let dragSize = dragText.size(withAttributes: dragAttrs)
            dragText.draw(at: CGPoint(x: (bounds.width - dragSize.width) / 2, y: 12), withAttributes: dragAttrs)
        }

        // Draw hand icon using SF Symbol
        let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .regular)
        if let handImage = UIImage(systemName: "hand.point.up.left.fill", withConfiguration: config) {
            let tintedImage = handImage.withTintColor(.systemPurple.withAlphaComponent(0.3), renderingMode: .alwaysOriginal)
            let imageRect = CGRect(
                x: (bounds.width - handImage.size.width) / 2,
                y: (bounds.height - handImage.size.height) / 2 - 10,
                width: handImage.size.width,
                height: handImage.size.height
            )
            tintedImage.draw(in: imageRect)
        }

        let text = isDragging ? "Release to drop" : "Double-tap & drag"
        let textSize = text.size(withAttributes: textAttrs)
        text.draw(at: CGPoint(x: (bounds.width - textSize.width) / 2, y: bounds.height / 2 + 20), withAttributes: textAttrs)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        // Disable parent scroll
        DispatchQueue.main.async {
            self.coordinator?.parent.isTouching = true
        }

        let allTouches = event?.allTouches ?? touches

        if allTouches.count == 2 {
            // Two-finger touch - prepare for scroll or right-click
            let touchArray = Array(allTouches)
            let loc1 = touchArray[0].location(in: self)
            let loc2 = touchArray[1].location(in: self)
            initialTwoFingerDistance = hypot(loc2.x - loc1.x, loc2.y - loc1.y)
            lastTwoFingerCenter = CGPoint(x: (loc1.x + loc2.x) / 2, y: (loc1.y + loc2.y) / 2)
            return
        }

        let location = touch.location(in: self)
        touchDownTime = Date()
        touchStartLocation = location
        lastLocation = location
        hasMoved = false
        totalMovement = 0

        // Check if this is a double-tap-to-drag (touch down shortly after a tap, near same location)
        potentialDragStart = false
        if let lastTap = lastTapTime, let lastTapLoc = lastTapLocation {
            let timeSinceLastTap = Date().timeIntervalSince(lastTap)
            let distanceFromLastTap = hypot(location.x - lastTapLoc.x, location.y - lastTapLoc.y)

            // Must be quick AND close to the first tap
            if timeSinceLastTap < doubleTapDragWindow && distanceFromLastTap < dragTapProximity {
                potentialDragStart = true
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let allTouches = event?.allTouches ?? touches

        // Two-finger scroll
        if allTouches.count == 2 {
            let touchArray = Array(allTouches)
            let loc1 = touchArray[0].location(in: self)
            let loc2 = touchArray[1].location(in: self)
            let center = CGPoint(x: (loc1.x + loc2.x) / 2, y: (loc1.y + loc2.y) / 2)

            if let lastCenter = lastTwoFingerCenter {
                let dy = center.y - lastCenter.y
                if abs(dy) > 2 {
                    coordinator?.parent.onScroll(dy * 0.5)
                }
            }
            lastTwoFingerCenter = center
            return
        }

        guard let touch = touches.first, let last = lastLocation else { return }

        let location = touch.location(in: self)
        let dx = location.x - last.x
        let dy = location.y - last.y

        // Track total movement for tap detection
        totalMovement += hypot(dx, dy)

        // Check if we've moved enough to count as movement
        if let start = touchStartLocation {
            let distanceFromStart = hypot(location.x - start.x, location.y - start.y)
            if distanceFromStart > moveThreshold && !hasMoved {
                hasMoved = true

                // If this was a potential drag (double-tap-hold), start dragging now
                if potentialDragStart && !isDragging {
                    startDragging()
                }
            }
        }

        // Send movement
        if abs(dx) > 0.5 || abs(dy) > 0.5 {
            coordinator?.parent.onMove(dx, dy)
        }

        lastLocation = location
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let allTouches = event?.allTouches ?? touches

        // Two-finger tap = right click
        if allTouches.count == 2 && initialTwoFingerDistance != nil {
            let touchArray = Array(allTouches)
            let loc1 = touchArray[0].location(in: self)
            let loc2 = touchArray[1].location(in: self)
            let finalDistance = hypot(loc2.x - loc1.x, loc2.y - loc1.y)

            // If fingers didn't move much, it's a two-finger tap
            if let initial = initialTwoFingerDistance, abs(finalDistance - initial) < 30 {
                hapticMedium.impactOccurred()
                coordinator?.parent.onTwoFingerTap()
            }

            initialTwoFingerDistance = nil
            lastTwoFingerCenter = nil
            return
        }

        // End drag if active
        if isDragging {
            endDragging()
            resetState()
            return
        }

        // Check for tap
        if let downTime = touchDownTime, let location = touchStartLocation, !hasMoved {
            let duration = Date().timeIntervalSince(downTime)

            if duration < tapThreshold && totalMovement < moveThreshold {
                // Check for double-tap (quick tap after previous tap)
                if let lastTap = lastTapTime, Date().timeIntervalSince(lastTap) < doubleTapInterval {
                    hapticMedium.impactOccurred()
                    coordinator?.parent.onDoubleTap()
                    lastTapTime = nil
                    lastTapLocation = nil
                } else {
                    // Single tap - record for potential double-tap or drag
                    hapticLight.impactOccurred()
                    coordinator?.parent.onTap()
                    lastTapTime = Date()
                    lastTapLocation = location

                    // Clear tap memory after window expires (prevents stale taps from triggering drag)
                    DispatchQueue.main.asyncAfter(deadline: .now() + doubleTapDragWindow + 0.1) { [weak self] in
                        guard let self = self else { return }
                        if let lastTap = self.lastTapTime, Date().timeIntervalSince(lastTap) > self.doubleTapDragWindow {
                            self.lastTapTime = nil
                            self.lastTapLocation = nil
                        }
                    }
                }
            }
        }

        resetState()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isDragging {
            endDragging()
        }

        resetState()
    }

    private func startDragging() {
        guard !isDragging else { return }
        isDragging = true
        hapticMedium.impactOccurred()
        coordinator?.parent.onDragStart()

        DispatchQueue.main.async {
            self.coordinator?.parent.isDragging = true
            self.setNeedsDisplay()
        }
    }

    private func endDragging() {
        guard isDragging else { return }
        isDragging = false
        hapticLight.impactOccurred()
        coordinator?.parent.onDragEnd()

        DispatchQueue.main.async {
            self.coordinator?.parent.isDragging = false
            self.setNeedsDisplay()
        }
    }

    private func resetState() {
        lastLocation = nil
        touchDownTime = nil
        touchStartLocation = nil
        hasMoved = false
        totalMovement = 0
        initialTwoFingerDistance = nil
        lastTwoFingerCenter = nil
        potentialDragStart = false

        // Re-enable parent scroll
        DispatchQueue.main.async {
            self.coordinator?.parent.isTouching = false
        }
    }
}

// MARK: - Mouse Button View

struct MouseButtonView: View {
    let title: String
    let action: () -> Void

    @State private var isPressed = false
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        Button(action: {
            hapticFeedback.impactOccurred()
            action()
        }) {
            Text(title)
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: [.hopPurple, .hopPink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: .hopPurple.opacity(0.3), radius: 4, y: 2)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Password Autofill View

struct PasswordAutofillView: View {
    let onPassword: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "key.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(colors: [.hopGold, .hopPink], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )

                Text("Type Password")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)

                Text("Tap the field below to use iOS Password AutoFill, then tap 'Type It' to send as keyboard input.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                PasswordTextField(onPassword: onPassword)
                    .frame(height: 50)
                    .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 40)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// UIKit wrapper for password field with AutoFill support
struct PasswordTextField: UIViewRepresentable {
    let onPassword: (String) -> Void

    func makeUIView(context: Context) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .fill
        stack.distribution = .fill

        let textField = UITextField()
        textField.placeholder = "Tap for Password AutoFill"
        textField.isSecureTextEntry = true
        textField.textContentType = .password
        textField.borderStyle = .roundedRect
        textField.font = .systemFont(ofSize: 16)
        textField.delegate = context.coordinator
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let button = UIButton(type: .system)
        button.setTitle("Type It", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.backgroundColor = UIColor(Color.hopPurple)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        button.addTarget(context.coordinator, action: #selector(Coordinator.typePassword), for: .touchUpInside)
        button.setContentHuggingPriority(.required, for: .horizontal)

        context.coordinator.textField = textField
        context.coordinator.onPassword = onPassword

        stack.addArrangedSubview(textField)
        stack.addArrangedSubview(button)

        return stack
    }

    func updateUIView(_ uiView: UIStackView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var textField: UITextField?
        var onPassword: ((String) -> Void)?

        @objc func typePassword() {
            guard let password = textField?.text, !password.isEmpty else { return }
            let haptic = UIImpactFeedbackGenerator(style: .medium)
            haptic.impactOccurred()
            onPassword?(password)
            textField?.text = ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            typePassword()
            return true
        }
    }
}

#Preview {
    TouchpadView()
        .environmentObject(BLEManager())
}
