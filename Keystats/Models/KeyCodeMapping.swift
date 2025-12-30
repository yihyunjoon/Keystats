import Carbon.HIToolbox

enum KeyCodeMapping {
    // MARK: - Key Code to Name Mapping

    static let keyNames: [Int: String] = [
        // Letters
        kVK_ANSI_A: "A",
        kVK_ANSI_B: "B",
        kVK_ANSI_C: "C",
        kVK_ANSI_D: "D",
        kVK_ANSI_E: "E",
        kVK_ANSI_F: "F",
        kVK_ANSI_G: "G",
        kVK_ANSI_H: "H",
        kVK_ANSI_I: "I",
        kVK_ANSI_J: "J",
        kVK_ANSI_K: "K",
        kVK_ANSI_L: "L",
        kVK_ANSI_M: "M",
        kVK_ANSI_N: "N",
        kVK_ANSI_O: "O",
        kVK_ANSI_P: "P",
        kVK_ANSI_Q: "Q",
        kVK_ANSI_R: "R",
        kVK_ANSI_S: "S",
        kVK_ANSI_T: "T",
        kVK_ANSI_U: "U",
        kVK_ANSI_V: "V",
        kVK_ANSI_W: "W",
        kVK_ANSI_X: "X",
        kVK_ANSI_Y: "Y",
        kVK_ANSI_Z: "Z",

        // Numbers
        kVK_ANSI_0: "0",
        kVK_ANSI_1: "1",
        kVK_ANSI_2: "2",
        kVK_ANSI_3: "3",
        kVK_ANSI_4: "4",
        kVK_ANSI_5: "5",
        kVK_ANSI_6: "6",
        kVK_ANSI_7: "7",
        kVK_ANSI_8: "8",
        kVK_ANSI_9: "9",

        // Function Keys
        kVK_F1: "F1",
        kVK_F2: "F2",
        kVK_F3: "F3",
        kVK_F4: "F4",
        kVK_F5: "F5",
        kVK_F6: "F6",
        kVK_F7: "F7",
        kVK_F8: "F8",
        kVK_F9: "F9",
        kVK_F10: "F10",
        kVK_F11: "F11",
        kVK_F12: "F12",
        kVK_F13: "F13",
        kVK_F14: "F14",
        kVK_F15: "F15",
        kVK_F16: "F16",
        kVK_F17: "F17",
        kVK_F18: "F18",
        kVK_F19: "F19",
        kVK_F20: "F20",

        // Modifier Keys
        kVK_Command: "⌘",
        kVK_RightCommand: "⌘R",
        kVK_Shift: "⇧",
        kVK_RightShift: "⇧R",
        kVK_Option: "⌥",
        kVK_RightOption: "⌥R",
        kVK_Control: "⌃",
        kVK_RightControl: "⌃R",
        kVK_CapsLock: "⇪",
        kVK_Function: "fn",

        // Special Keys
        kVK_Space: "␣",
        kVK_Return: "↩",
        kVK_Tab: "⇥",
        kVK_Delete: "⌫",
        kVK_ForwardDelete: "⌦",
        kVK_Escape: "⎋",

        // Arrow Keys
        kVK_LeftArrow: "←",
        kVK_RightArrow: "→",
        kVK_UpArrow: "↑",
        kVK_DownArrow: "↓",

        // Navigation Keys
        kVK_Home: "↖",
        kVK_End: "↘",
        kVK_PageUp: "⇞",
        kVK_PageDown: "⇟",

        // Punctuation and Symbols
        kVK_ANSI_Grave: "`",
        kVK_ANSI_Minus: "-",
        kVK_ANSI_Equal: "=",
        kVK_ANSI_LeftBracket: "[",
        kVK_ANSI_RightBracket: "]",
        kVK_ANSI_Backslash: "\\",
        kVK_ANSI_Semicolon: ";",
        kVK_ANSI_Quote: "'",
        kVK_ANSI_Comma: ",",
        kVK_ANSI_Period: ".",
        kVK_ANSI_Slash: "/",

        // Keypad
        kVK_ANSI_Keypad0: "Keypad 0",
        kVK_ANSI_Keypad1: "Keypad 1",
        kVK_ANSI_Keypad2: "Keypad 2",
        kVK_ANSI_Keypad3: "Keypad 3",
        kVK_ANSI_Keypad4: "Keypad 4",
        kVK_ANSI_Keypad5: "Keypad 5",
        kVK_ANSI_Keypad6: "Keypad 6",
        kVK_ANSI_Keypad7: "Keypad 7",
        kVK_ANSI_Keypad8: "Keypad 8",
        kVK_ANSI_Keypad9: "Keypad 9",
        kVK_ANSI_KeypadDecimal: "Keypad .",
        kVK_ANSI_KeypadPlus: "Keypad +",
        kVK_ANSI_KeypadMinus: "Keypad -",
        kVK_ANSI_KeypadMultiply: "Keypad *",
        kVK_ANSI_KeypadDivide: "Keypad /",
        kVK_ANSI_KeypadEquals: "Keypad =",
        kVK_ANSI_KeypadEnter: "Keypad Enter",
        kVK_ANSI_KeypadClear: "Keypad Clear",

        // Media Keys
        kVK_VolumeUp: "Volume Up",
        kVK_VolumeDown: "Volume Down",
        kVK_Mute: "Mute",

        // Help
        kVK_Help: "Help",
    ]

    // MARK: - Public Methods

    static func name(for keyCode: Int) -> String {
        keyNames[keyCode] ?? "Key \(keyCode)"
    }

    static func name(for keyCode: Int64) -> String {
        name(for: Int(keyCode))
    }

    static func keyCode(for name: String) -> Int {
        keyNames.first { $0.value == name }?.key ?? 0
    }
}
