import Cocoa
import CGSBridge

/// Manages detection of macOS spaces (virtual desktops) using private CoreGraphics APIs.
final class SpaceManager {
    static let shared = SpaceManager()

    /// Whether the private CGS APIs are available at runtime.
    let isAvailable: Bool

    private let conn: CGSConnectionID

    private init() {
        // Verify private symbols exist before calling them
        let handle = dlopen(nil, RTLD_LAZY)
        let available = handle != nil
            && dlsym(handle, "CGSMainConnectionID") != nil
            && dlsym(handle, "CGSGetActiveSpace") != nil
            && dlsym(handle, "CGSCopyManagedDisplaySpaces") != nil
        if let handle { dlclose(handle) }

        isAvailable = available
        conn = available ? CGSMainConnectionID() : 0
    }

    /// Returns the ID of the currently active space, or 0 if APIs are unavailable.
    func activeSpaceID() -> CGSSpaceID {
        guard isAvailable else { return 0 }
        return CGSGetActiveSpace(conn)
    }

    /// Returns an ordered list of user space IDs for the main display.
    /// The order matches the left-to-right arrangement in Mission Control.
    func allUserSpaceIDs() -> [CGSSpaceID] {
        guard isAvailable else { return [] }
        guard let displays = CGSCopyManagedDisplaySpaces(conn) as? [[String: Any]] else {
            return []
        }

        var spaceIDs: [CGSSpaceID] = []
        for display in displays {
            guard let spaces = display["Spaces"] as? [[String: Any]] else { continue }
            for space in spaces {
                // type 0 = regular user space (not fullscreen or system)
                guard let type = space["type"] as? Int, type == 0 else { continue }
                if let id = space["ManagedSpaceID"] as? CGSSpaceID {
                    spaceIDs.append(id)
                } else if let id = space["id64"] as? CGSSpaceID {
                    spaceIDs.append(id)
                }
            }
        }
        return spaceIDs
    }

    /// Returns the 1-based index of the current space among all user spaces.
    func activeSpaceIndex() -> Int? {
        let active = activeSpaceID()
        guard active != 0 else { return nil }
        let all = allUserSpaceIDs()
        guard let idx = all.firstIndex(of: active) else { return nil }
        return idx + 1
    }
}
