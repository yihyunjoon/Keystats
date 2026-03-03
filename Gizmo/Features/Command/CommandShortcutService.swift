import AppKit
import Foundation
import KeyboardShortcuts
import Observation

@Observable
@MainActor
final class CommandShortcutService {
  private let windowManagerService: WindowManagerService
  private let virtualWorkspaceService: VirtualWorkspaceService

  private(set) var commands: [LauncherCommand]
  private var shortcutEventTasks: [String: Task<Void, Never>] = [:]

  init(
    windowManagerService: WindowManagerService,
    virtualWorkspaceService: VirtualWorkspaceService,
    initialWorkspaceNames: [String]
  ) {
    self.windowManagerService = windowManagerService
    self.virtualWorkspaceService = virtualWorkspaceService
    self.commands = LauncherCommand.makeAll(workspaceNames: initialWorkspaceNames)
    rebuildShortcutEventStreams()
  }

  func stop() {
    for task in shortcutEventTasks.values {
      task.cancel()
    }
    shortcutEventTasks.removeAll()
  }

  func updateWorkspaceCommands(workspaceNames: [String]) {
    let nextCommands = LauncherCommand.makeAll(workspaceNames: workspaceNames)
    guard nextCommands != commands else { return }

    commands = nextCommands
    rebuildShortcutEventStreams()
  }

  func shortcutName(for command: LauncherCommand) -> KeyboardShortcuts.Name {
    KeyboardShortcuts.Name(shortcutNameRawValue(for: command.id))
  }

  func execute(
    _ command: LauncherCommand,
    preferredWindowElement: AXUIElement? = nil
  ) -> Result<Void, LauncherCommandError> {
    switch command.action {
    case .tile(let tileAction):
      return mapWindowManagerResult(
        windowManagerService.execute(
          tileAction,
          preferredWindowElement: preferredWindowElement
        )
      )
    case .workspaceFocus(let workspaceName):
      return mapWorkspaceResult(
        virtualWorkspaceService.focusWorkspace(workspaceName)
      )
    case .workspaceBackAndForth:
      return mapWorkspaceResult(
        virtualWorkspaceService.focusPreviousWorkspace()
      )
    case .moveFocusedWindowToWorkspace(let workspaceName):
      return mapWorkspaceResult(
        virtualWorkspaceService.moveFocusedWindowToWorkspace(
          workspaceName,
          preferredWindowElement: preferredWindowElement
        )
      )
    }
  }

  private func mapWindowManagerResult(
    _ result: Result<Void, WindowManagerError>
  ) -> Result<Void, LauncherCommandError> {
    switch result {
    case .success:
      return .success(())
    case .failure(let error):
      return .failure(.windowManager(error))
    }
  }

  private func mapWorkspaceResult(
    _ result: Result<Void, WorkspaceError>
  ) -> Result<Void, LauncherCommandError> {
    switch result {
    case .success:
      return .success(())
    case .failure(let error):
      return .failure(.workspace(error))
    }
  }

  private func rebuildShortcutEventStreams() {
    for task in shortcutEventTasks.values {
      task.cancel()
    }
    shortcutEventTasks.removeAll()

    for command in commands {
      let shortcutName = shortcutName(for: command)
      let commandID = command.id

      shortcutEventTasks[commandID] = Task { @MainActor [weak self] in
        for await _ in KeyboardShortcuts.events(.keyUp, for: shortcutName) {
          guard let self else { return }
          guard let command = self.commands.first(where: { $0.id == commandID }) else { continue }
          _ = self.execute(command)
        }
      }
    }
  }

  private func shortcutNameRawValue(for commandID: String) -> String {
    let encoded = Data(commandID.utf8)
      .base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")

    return "command.\(encoded)"
  }
}
