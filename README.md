<p align="center">
  <img src="docs/images/hopguy.png" width="200" alt="HID-HOP Mascot">
</p>

<h1 align="center">HID-HOP iOS</h1>

<p align="center">
  <strong>iOS companion app for the HID-HOP dongle</strong>
</p>

<p align="center">
  Turn your iPhone into a wireless keyboard and mouse
</p>

---

## What is HID-HOP?

HID-HOP turns your iPhone into a wireless keyboard and trackpad for any computer. Just plug the HID-HOP dongle into a USB port, connect with the app, and you're ready to go - no drivers needed.

## Features

- **Virtual Trackpad** - Natural gestures with tap-to-click, two-finger scroll, and drag support
- **Virtual Keyboard** - Full text input with special keys
- **Quick Actions** - One-tap shortcuts for screenshots, media controls, and more
- **Media Controls** - Play/pause, volume, track skip
- **PIN Protection** - Secure your dongle with a 4-8 digit PIN
- **Custom Device Names** - Rename your dongle for easy identification

## Screenshots

<p align="center">
  <i>Coming soon</i>
</p>

## Requirements

- iOS 16.0+
- iPhone with Bluetooth 4.0+
- HID-HOP dongle ([firmware](https://github.com/nathanabrewer/hid-hop-firmware))

## Installation

### App Store

Coming soon!

### Build from Source

1. Clone the repository
2. Open `BLEHIDBridge.xcodeproj` in Xcode
3. Select your development team
4. Build and run on your device

## Usage

1. Plug the HID-HOP dongle into your computer's USB port
2. Open the HID-HOP app on your iPhone
3. Tap "Scan for Devices"
4. Select your dongle from the list
5. Start controlling your computer!

### Trackpad Gestures

| Gesture | Action |
|---------|--------|
| Single tap | Left click |
| Two-finger tap | Right click |
| Two-finger drag | Scroll |
| Double-tap + drag | Click and drag |

### Quick Actions

- Lock Screen
- Screenshot / Area Screenshot
- Mission Control
- App Switcher (Cmd+Tab)
- Spotlight Search
- Media controls (play/pause, volume, track skip)
- Browser shortcuts (refresh, back, forward, new tab)

## Project Structure

```
ios-app/
└── BLEHIDBridge/
    ├── Services/
    │   ├── BLEManager.swift      # CoreBluetooth handling
    │   └── HIDProtocol.swift     # Binary protocol encoding
    ├── Views/
    │   ├── ContentView.swift     # Main navigation
    │   ├── TouchpadView.swift    # Virtual trackpad
    │   ├── KeyboardView.swift    # Virtual keyboard
    │   ├── QuickActionsView.swift
    │   └── SettingsView.swift
    └── Assets.xcassets/
```

## License

Copyright (c) 2025 Nathan Brewer. All Rights Reserved.

See [LICENSE](LICENSE) for details.

## Related Projects

- [hid-hop-firmware](https://github.com/nathanabrewer/hid-hop-firmware) - nRF52840 dongle firmware
