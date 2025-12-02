/*
 * HID-HOP - Quick Actions View
 */

import SwiftUI

struct QuickActionsView: View {
    @EnvironmentObject var bleManager: BLEManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // System controls
                VStack(alignment: .leading, spacing: 12) {
                    Text("System Controls")
                        .font(.headline)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        QuickActionButton(
                            title: "Lock Screen",
                            icon: "lock.fill",
                            color: .purple
                        ) {
                            // Cmd+Ctrl+Q on macOS
                            bleManager.sendKeyCombo(modifiers: [.gui, .ctrl], key: .q)
                        }

                        QuickActionButton(
                            title: "Screenshot",
                            icon: "camera.fill",
                            color: .blue
                        ) {
                            // Cmd+Shift+3 on macOS
                            bleManager.sendKeyCombo(modifiers: [.gui, .shift], key: .three)
                        }

                        QuickActionButton(
                            title: "Area Screenshot",
                            icon: "crop",
                            color: .blue
                        ) {
                            // Cmd+Shift+4 on macOS
                            bleManager.sendKeyCombo(modifiers: [.gui, .shift], key: .four)
                        }

                        QuickActionButton(
                            title: "Mission Control",
                            icon: "rectangle.3.group",
                            color: .orange
                        ) {
                            // Ctrl+Up Arrow
                            bleManager.sendKeyCombo(modifiers: .ctrl, key: .arrowUp)
                        }

                        QuickActionButton(
                            title: "App Switcher",
                            icon: "square.stack.3d.up",
                            color: .green
                        ) {
                            // Cmd+Tab
                            bleManager.sendKeyCombo(modifiers: .gui, key: .tab)
                        }

                        QuickActionButton(
                            title: "Spotlight",
                            icon: "magnifyingglass",
                            color: .gray
                        ) {
                            // Cmd+Space
                            bleManager.sendKeyCombo(modifiers: .gui, key: .space)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Media controls
                VStack(alignment: .leading, spacing: 12) {
                    Text("Media Controls")
                        .font(.headline)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        QuickActionButton(
                            title: "Previous",
                            icon: "backward.fill",
                            color: .pink
                        ) {
                            bleManager.sendMediaKey(.previousTrack)
                        }

                        QuickActionButton(
                            title: "Play/Pause",
                            icon: "playpause.fill",
                            color: .pink
                        ) {
                            bleManager.sendMediaKey(.playPause)
                        }

                        QuickActionButton(
                            title: "Next",
                            icon: "forward.fill",
                            color: .pink
                        ) {
                            bleManager.sendMediaKey(.nextTrack)
                        }

                        QuickActionButton(
                            title: "Vol Down",
                            icon: "speaker.minus.fill",
                            color: .indigo
                        ) {
                            bleManager.sendMediaKey(.volumeDown)
                        }

                        QuickActionButton(
                            title: "Mute",
                            icon: "speaker.slash.fill",
                            color: .indigo
                        ) {
                            bleManager.sendMediaKey(.mute)
                        }

                        QuickActionButton(
                            title: "Vol Up",
                            icon: "speaker.plus.fill",
                            color: .indigo
                        ) {
                            bleManager.sendMediaKey(.volumeUp)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Browser shortcuts
                VStack(alignment: .leading, spacing: 12) {
                    Text("Browser")
                        .font(.headline)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        QuickActionButton(
                            title: "Refresh",
                            icon: "arrow.clockwise",
                            color: .teal
                        ) {
                            bleManager.sendKeyCombo(modifiers: .gui, key: .r)
                        }

                        QuickActionButton(
                            title: "Back",
                            icon: "arrow.left",
                            color: .teal
                        ) {
                            bleManager.sendKeyCombo(modifiers: .gui, key: .leftBracket)
                        }

                        QuickActionButton(
                            title: "Forward",
                            icon: "arrow.right",
                            color: .teal
                        ) {
                            bleManager.sendKeyCombo(modifiers: .gui, key: .rightBracket)
                        }

                        QuickActionButton(
                            title: "New Tab",
                            icon: "plus.square",
                            color: .teal
                        ) {
                            bleManager.sendKeyCombo(modifiers: .gui, key: .t)
                        }

                        QuickActionButton(
                            title: "Close Tab",
                            icon: "xmark.square",
                            color: .teal
                        ) {
                            bleManager.sendKeyCombo(modifiers: .gui, key: .w)
                        }

                        QuickActionButton(
                            title: "Address Bar",
                            icon: "link",
                            color: .teal
                        ) {
                            bleManager.sendKeyCombo(modifiers: .gui, key: .l)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(12)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

#Preview {
    QuickActionsView()
        .environmentObject(BLEManager())
}
