import Foundation

enum AppRuntime {
  nonisolated static var isPreview: Bool {
    let environment = ProcessInfo.processInfo.environment
    return environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
      || environment["XCODE_RUNNING_FOR_PLAYGROUNDS"] == "1"
  }
}
