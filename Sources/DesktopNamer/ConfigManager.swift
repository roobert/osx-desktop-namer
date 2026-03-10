import Foundation
import CGSBridge

/// Persists desktop name mappings and preferences to disk.
final class ConfigManager {
    static let shared = ConfigManager()

    private let configURL: URL
    /// Maps space ID (as String) to user-assigned name.
    private var names: [String: String] = [:]
    /// Whether the HUD overlay is shown on space switch.
    private(set) var overlayEnabled: Bool = true

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("DesktopNamer", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: dir, withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700])
        configURL = dir.appendingPathComponent("config.json")
        load()
    }

    // MARK: - Public

    func name(forSpaceID id: CGSSpaceID) -> String? {
        return names[String(id)]
    }

    func setName(_ name: String?, forSpaceID id: CGSSpaceID) {
        let key = String(id)
        if let name = name, !name.isEmpty {
            names[key] = name
        } else {
            names.removeValue(forKey: key)
        }
        save()
    }

    func resetAll() {
        names.removeAll()
        save()
    }

    func setOverlayEnabled(_ enabled: Bool) {
        overlayEnabled = enabled
        save()
    }

    /// Returns the display name for a space: its custom name, or "Desktop N" as fallback.
    func displayName(forSpaceID id: CGSSpaceID, index: Int) -> String {
        return names[String(id)] ?? "Desktop \(index)"
    }

    // MARK: - Persistence

    private struct Config: Codable {
        var names: [String: String] = [:]
        var overlayEnabled: Bool? = true
    }

    private func load() {
        guard let data = try? Data(contentsOf: configURL),
              let config = try? JSONDecoder().decode(Config.self, from: data) else {
            return
        }
        names = config.names
        overlayEnabled = config.overlayEnabled ?? true
    }

    private func save() {
        let config = Config(names: names, overlayEnabled: overlayEnabled)
        guard let data = try? JSONEncoder().encode(config) else { return }
        try? data.write(to: configURL, options: .atomic)
        try? FileManager.default.setAttributes(
            [.posixPermissions: 0o600], ofItemAtPath: configURL.path)
    }
}
