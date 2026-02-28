import Foundation
import KeyboardShortcuts
import TOMLKit

struct GizmoConfigParser {
  func parse(_ rawToml: String) -> (config: GizmoConfig?, errors: [String]) {
    let rawTable: TOMLTable

    do {
      rawTable = try TOMLTable(string: rawToml)
    } catch let error as TOMLParseError {
      return (nil, ["syntax: \(error.debugDescription)"])
    } catch {
      return (nil, ["syntax: \(error.localizedDescription)"])
    }

    var config = GizmoConfig.default
    var errors: [String] = []

    let allowedRootKeys: Set<String> = ["config-version", "launcher", "keystats"]
    appendUnknownKeys(
      in: rawTable,
      allowed: allowedRootKeys,
      prefix: "",
      errors: &errors
    )

    if let versionValue = rawTable["config-version"] {
      if let version = versionValue.int {
        if version == GizmoConfig.supportedConfigVersion {
          config.configVersion = version
        } else {
          errors.append(
            "config-version: Unsupported value '\(version)'. Only \(GizmoConfig.supportedConfigVersion) is supported."
          )
        }
      } else {
        errors.append("config-version: Expected int, got \(versionValue.type)")
      }
    }

    if let launcherValue = rawTable["launcher"] {
      parseLauncher(launcherValue, config: &config, errors: &errors)
    }

    if let keystatsValue = rawTable["keystats"] {
      parseKeystats(keystatsValue, config: &config, errors: &errors)
    }

    return errors.isEmpty ? (config, []) : (nil, errors)
  }

  private func parseLauncher(
    _ raw: TOMLValueConvertible,
    config: inout GizmoConfig,
    errors: inout [String]
  ) {
    guard let launcherTable = raw.table else {
      errors.append("launcher: Expected table, got \(raw.type)")
      return
    }

    appendUnknownKeys(
      in: launcherTable,
      allowed: ["display", "force_english_input_source", "global_hotkey"],
      prefix: "launcher",
      errors: &errors
    )

    if let displayRaw = launcherTable["display"] {
      guard let displayString = displayRaw.string else {
        errors.append("launcher.display: Expected string, got \(displayRaw.type)")
        return
      }

      guard let display = LauncherDisplay(rawValue: displayString) else {
        errors.append(
          "launcher.display: Invalid value '\(displayString)'. Allowed: primary, mouse, active_window."
        )
        return
      }

      config.launcher.display = display
    }

    if let forceEnglishRaw = launcherTable["force_english_input_source"] {
      guard let forceEnglish = forceEnglishRaw.bool else {
        errors.append(
          "launcher.force_english_input_source: Expected bool, got \(forceEnglishRaw.type)"
        )
        return
      }

      config.launcher.forceEnglishInputSource = forceEnglish
    }

    if let hotkeyRaw = launcherTable["global_hotkey"] {
      parseGlobalHotkey(
        hotkeyRaw,
        hotkey: &config.launcher.globalHotkey,
        errors: &errors
      )
    }
  }

  private func parseGlobalHotkey(
    _ raw: TOMLValueConvertible,
    hotkey: inout HotkeyConfig,
    errors: inout [String]
  ) {
    guard let hotkeyTable = raw.table else {
      errors.append("launcher.global_hotkey: Expected table, got \(raw.type)")
      return
    }

    appendUnknownKeys(
      in: hotkeyTable,
      allowed: ["key", "modifiers"],
      prefix: "launcher.global_hotkey",
      errors: &errors
    )

    if let keyRaw = hotkeyTable["key"] {
      guard let key = keyRaw.string else {
        errors.append("launcher.global_hotkey.key: Expected string, got \(keyRaw.type)")
        return
      }

      if KeyboardShortcuts.Key.fromConfigKey(key) == nil {
        errors.append("launcher.global_hotkey.key: Unsupported key '\(key)'.")
      } else {
        hotkey.key = key
      }
    }

    if let modifiersRaw = hotkeyTable["modifiers"] {
      guard let modifiersArray = modifiersRaw.array else {
        errors.append(
          "launcher.global_hotkey.modifiers: Expected array, got \(modifiersRaw.type)"
        )
        return
      }

      var parsedModifiers: [HotkeyModifier] = []

      for (index, value) in modifiersArray.enumerated() {
        guard let modifierValue = value.string else {
          errors.append(
            "launcher.global_hotkey.modifiers[\(index)]: Expected string, got \(value.type)"
          )
          continue
        }

        guard let modifier = HotkeyModifier(rawValue: modifierValue) else {
          errors.append(
            "launcher.global_hotkey.modifiers[\(index)]: Invalid value '\(modifierValue)'. Allowed: command, shift, option, control, function."
          )
          continue
        }

        parsedModifiers.append(modifier)
      }

      hotkey.modifiers = parsedModifiers
    }
  }

  private func parseKeystats(
    _ raw: TOMLValueConvertible,
    config: inout GizmoConfig,
    errors: inout [String]
  ) {
    guard let keystatsTable = raw.table else {
      errors.append("keystats: Expected table, got \(raw.type)")
      return
    }

    appendUnknownKeys(
      in: keystatsTable,
      allowed: ["auto_start_monitoring"],
      prefix: "keystats",
      errors: &errors
    )

    if let autoStartRaw = keystatsTable["auto_start_monitoring"] {
      guard let autoStart = autoStartRaw.bool else {
        errors.append(
          "keystats.auto_start_monitoring: Expected bool, got \(autoStartRaw.type)"
        )
        return
      }

      config.keystats.autoStartMonitoring = autoStart
    }
  }

  private func appendUnknownKeys(
    in table: TOMLTable,
    allowed: Set<String>,
    prefix: String,
    errors: inout [String]
  ) {
    for (key, _) in table where !allowed.contains(key) {
      let path = prefix.isEmpty ? key : "\(prefix).\(key)"
      errors.append("\(path): Unknown key.")
    }
  }
}
