import AppKit
import Observation

@Observable
@MainActor
final class ConfigStore {
  private(set) var active: GizmoConfig = .default
  private(set) var configURL: URL
  private(set) var lastLoadError: String?

  var onConfigDidLoad: ((GizmoConfig) -> Void)?

  private let pathResolver: ConfigPathResolver
  private let parser: GizmoConfigParser

  init(
    pathResolver: ConfigPathResolver? = nil,
    parser: GizmoConfigParser? = nil
  ) {
    self.pathResolver = pathResolver ?? ConfigPathResolver()
    self.parser = parser ?? GizmoConfigParser()
    self.configURL = self.pathResolver.resolveConfigURL()
  }

  func bootstrapAndLoad() {
    configURL = pathResolver.resolveConfigURL()

    do {
      try pathResolver.ensureConfigFileExists(at: configURL)
    } catch {
      lastLoadError = "Failed to initialize config file: \(error.localizedDescription)"
      return
    }

    _ = reload()
  }

  @discardableResult
  func reload() -> Bool {
    do {
      let rawToml = try String(contentsOf: configURL, encoding: .utf8)
      let parseResult = parser.parse(rawToml)

      if let config = parseResult.config {
        active = config
        lastLoadError = nil
        onConfigDidLoad?(config)
        return true
      }

      lastLoadError = parseResult.errors.joined(separator: "\n")
      return false
    } catch {
      lastLoadError = "Failed to read \(configURL.path()): \(error.localizedDescription)"
      return false
    }
  }

  func openConfigFile() {
    NSWorkspace.shared.open(configURL)
  }

  func revealConfigFile() {
    NSWorkspace.shared.activateFileViewerSelecting([configURL])
  }
}
