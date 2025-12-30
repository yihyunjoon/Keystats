import Carbon.HIToolbox

struct KeyDefinition {
  let keyCode: Int
  let width: CGFloat  // Relative width (1.0 = standard key)

  init(_ keyCode: Int, width: CGFloat = 1.0) {
    self.keyCode = keyCode
    self.width = width
  }
}

enum KeyboardLayoutData {
  static let baseKeySize: CGFloat = 44
  static let keySpacing: CGFloat = 4

  static let rows: [[KeyDefinition]] = [
    // Row 0: Function row
    [
      KeyDefinition(kVK_Escape),
      KeyDefinition(kVK_F1),
      KeyDefinition(kVK_F2),
      KeyDefinition(kVK_F3),
      KeyDefinition(kVK_F4),
      KeyDefinition(kVK_F5),
      KeyDefinition(kVK_F6),
      KeyDefinition(kVK_F7),
      KeyDefinition(kVK_F8),
      KeyDefinition(kVK_F9),
      KeyDefinition(kVK_F10),
      KeyDefinition(kVK_F11),
      KeyDefinition(kVK_F12),
    ],
    // Row 1: Number row
    [
      KeyDefinition(kVK_ANSI_Grave),
      KeyDefinition(kVK_ANSI_1),
      KeyDefinition(kVK_ANSI_2),
      KeyDefinition(kVK_ANSI_3),
      KeyDefinition(kVK_ANSI_4),
      KeyDefinition(kVK_ANSI_5),
      KeyDefinition(kVK_ANSI_6),
      KeyDefinition(kVK_ANSI_7),
      KeyDefinition(kVK_ANSI_8),
      KeyDefinition(kVK_ANSI_9),
      KeyDefinition(kVK_ANSI_0),
      KeyDefinition(kVK_ANSI_Minus),
      KeyDefinition(kVK_ANSI_Equal),
      KeyDefinition(kVK_Delete, width: 1.5),
    ],
    // Row 2: QWERTY row
    [
      KeyDefinition(kVK_Tab, width: 1.5),
      KeyDefinition(kVK_ANSI_Q),
      KeyDefinition(kVK_ANSI_W),
      KeyDefinition(kVK_ANSI_E),
      KeyDefinition(kVK_ANSI_R),
      KeyDefinition(kVK_ANSI_T),
      KeyDefinition(kVK_ANSI_Y),
      KeyDefinition(kVK_ANSI_U),
      KeyDefinition(kVK_ANSI_I),
      KeyDefinition(kVK_ANSI_O),
      KeyDefinition(kVK_ANSI_P),
      KeyDefinition(kVK_ANSI_LeftBracket),
      KeyDefinition(kVK_ANSI_RightBracket),
      KeyDefinition(kVK_ANSI_Backslash),
    ],
    // Row 3: Home row
    [
      KeyDefinition(kVK_CapsLock, width: 1.75),
      KeyDefinition(kVK_ANSI_A),
      KeyDefinition(kVK_ANSI_S),
      KeyDefinition(kVK_ANSI_D),
      KeyDefinition(kVK_ANSI_F),
      KeyDefinition(kVK_ANSI_G),
      KeyDefinition(kVK_ANSI_H),
      KeyDefinition(kVK_ANSI_J),
      KeyDefinition(kVK_ANSI_K),
      KeyDefinition(kVK_ANSI_L),
      KeyDefinition(kVK_ANSI_Semicolon),
      KeyDefinition(kVK_ANSI_Quote),
      KeyDefinition(kVK_Return, width: 1.75),
    ],
    // Row 4: Bottom letter row
    [
      KeyDefinition(kVK_Shift, width: 2.25),
      KeyDefinition(kVK_ANSI_Z),
      KeyDefinition(kVK_ANSI_X),
      KeyDefinition(kVK_ANSI_C),
      KeyDefinition(kVK_ANSI_V),
      KeyDefinition(kVK_ANSI_B),
      KeyDefinition(kVK_ANSI_N),
      KeyDefinition(kVK_ANSI_M),
      KeyDefinition(kVK_ANSI_Comma),
      KeyDefinition(kVK_ANSI_Period),
      KeyDefinition(kVK_ANSI_Slash),
      KeyDefinition(kVK_RightShift, width: 2.25),
    ],
    // Row 5: Modifier row
    [
      KeyDefinition(kVK_Function, width: 1.25),
      KeyDefinition(kVK_Control, width: 1.25),
      KeyDefinition(kVK_Option, width: 1.25),
      KeyDefinition(kVK_Command, width: 1.25),
      KeyDefinition(kVK_Space, width: 5.0),
      KeyDefinition(kVK_RightCommand, width: 1.25),
      KeyDefinition(kVK_RightOption, width: 1.25),
      KeyDefinition(kVK_LeftArrow),
      KeyDefinition(kVK_UpArrow),
      KeyDefinition(kVK_DownArrow),
      KeyDefinition(kVK_RightArrow),
    ],
  ]
}
