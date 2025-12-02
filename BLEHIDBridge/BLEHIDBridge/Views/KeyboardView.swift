/*
 * HID-HOP - Keyboard View
 */

import SwiftUI

struct KeyboardView: View {
    @EnvironmentObject var bleManager: BLEManager
    @State private var textInput = ""
    @State private var showingPasswordSheet = false
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Text input section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Type Text")
                        .font(.headline)

                    HStack {
                        TextField("Enter text to send...", text: $textInput)
                            .textFieldStyle(.roundedBorder)
                            .focused($isTextFieldFocused)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                        Button(action: sendText) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                        }
                        .disabled(textInput.isEmpty)
                    }

                    Text("Text will be typed character by character")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Quick type buttons
                VStack(alignment: .leading, spacing: 12) {
                    Text("Special Keys")
                        .font(.headline)

                    // Navigation keys
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 10) {
                        SpecialKeyButton(title: "Tab", icon: "arrow.right.to.line") {
                            bleManager.sendSpecialKey(.tab)
                        }
                        SpecialKeyButton(title: "Enter", icon: "return") {
                            bleManager.sendSpecialKey(.enter)
                        }
                        SpecialKeyButton(title: "Esc", icon: "escape") {
                            bleManager.sendSpecialKey(.escape)
                        }
                        SpecialKeyButton(title: "Del", icon: "delete.right") {
                            bleManager.sendSpecialKey(.delete)
                        }
                    }

                    // Arrow keys
                    HStack {
                        Spacer()
                        SpecialKeyButton(title: "", icon: "arrow.up") {
                            bleManager.sendSpecialKey(.arrowUp)
                        }
                        Spacer()
                    }

                    HStack(spacing: 10) {
                        Spacer()
                        SpecialKeyButton(title: "", icon: "arrow.left") {
                            bleManager.sendSpecialKey(.arrowLeft)
                        }
                        SpecialKeyButton(title: "", icon: "arrow.down") {
                            bleManager.sendSpecialKey(.arrowDown)
                        }
                        SpecialKeyButton(title: "", icon: "arrow.right") {
                            bleManager.sendSpecialKey(.arrowRight)
                        }
                        Spacer()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Keyboard shortcuts
                VStack(alignment: .leading, spacing: 12) {
                    Text("Keyboard Shortcuts")
                        .font(.headline)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 10) {
                        ShortcutButton(title: "Copy", shortcut: "Cmd+C") {
                            bleManager.sendKeyCombo(modifiers: .gui, key: .c)
                        }
                        ShortcutButton(title: "Paste", shortcut: "Cmd+V") {
                            bleManager.sendKeyCombo(modifiers: .gui, key: .v)
                        }
                        ShortcutButton(title: "Cut", shortcut: "Cmd+X") {
                            bleManager.sendKeyCombo(modifiers: .gui, key: .x)
                        }
                        ShortcutButton(title: "Undo", shortcut: "Cmd+Z") {
                            bleManager.sendKeyCombo(modifiers: .gui, key: .z)
                        }
                        ShortcutButton(title: "Select All", shortcut: "Cmd+A") {
                            bleManager.sendKeyCombo(modifiers: .gui, key: .a)
                        }
                        ShortcutButton(title: "Find", shortcut: "Cmd+F") {
                            bleManager.sendKeyCombo(modifiers: .gui, key: .f)
                        }
                        ShortcutButton(title: "Save", shortcut: "Cmd+S") {
                            bleManager.sendKeyCombo(modifiers: .gui, key: .s)
                        }
                        ShortcutButton(title: "New Tab", shortcut: "Cmd+T") {
                            bleManager.sendKeyCombo(modifiers: .gui, key: .t)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Password entry
                VStack(alignment: .leading, spacing: 12) {
                    Text("Secure Entry")
                        .font(.headline)

                    Button(action: { showingPasswordSheet = true }) {
                        HStack {
                            Image(systemName: "key.fill")
                            Text("Type Password")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }

                    Text("Securely type passwords without showing on screen")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
        .sheet(isPresented: $showingPasswordSheet) {
            PasswordEntrySheet()
        }
    }

    private func sendText() {
        guard !textInput.isEmpty else { return }
        bleManager.sendText(textInput)
        textInput = ""
        isTextFieldFocused = false
    }
}

// MARK: - Special Key Button

struct SpecialKeyButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                if !title.isEmpty {
                    Text(title)
                        .font(.caption)
                }
            }
            .frame(width: 60, height: 50)
            .background(Color(.systemGray4))
            .foregroundColor(.primary)
            .cornerRadius(8)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

// MARK: - Shortcut Button

struct ShortcutButton: View {
    let title: String
    let shortcut: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(shortcut)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color(.systemGray4))
            .foregroundColor(.primary)
            .cornerRadius(8)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

// MARK: - Password Entry Sheet

struct PasswordEntrySheet: View {
    @EnvironmentObject var bleManager: BLEManager
    @Environment(\.dismiss) var dismiss
    @State private var password = ""
    @State private var isSecure = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "key.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)

                Text("Enter Password")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("The password will be typed directly without displaying on the connected computer.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                HStack {
                    if isSecure {
                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    } else {
                        TextField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }

                    Button(action: { isSecure.toggle() }) {
                        Image(systemName: isSecure ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                Button(action: typePassword) {
                    Text("Type Password")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(password.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(password.isEmpty)
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
    }

    private func typePassword() {
        bleManager.sendText(password)
        password = ""
        dismiss()
    }
}

#Preview {
    KeyboardView()
        .environmentObject(BLEManager())
}
