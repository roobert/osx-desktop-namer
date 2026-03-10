import Cocoa
import CGSBridge
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let overlayPanel = OverlayPanel(
        contentRect: NSRect(x: 0, y: 0, width: 200, height: 80),
        styleMask: [],
        backing: .buffered,
        defer: false
    )
    private var currentSpaceID: CGSSpaceID = 0
    private var overlayTimer: Timer?

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .medium)
        }

        currentSpaceID = SpaceManager.shared.activeSpaceID()
        refreshUI()

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleSpaceChange()
        }
    }

    // MARK: - Space changes

    private func handleSpaceChange() {
        let newID = SpaceManager.shared.activeSpaceID()
        guard newID != currentSpaceID else { return }
        currentSpaceID = newID

        refreshUI()

        // Immediately hide the overlay so it doesn't appear during the swipe animation
        overlayTimer?.invalidate()
        overlayPanel.cancelAndHide()

        // Show it fresh after the space-switch animation finishes
        guard ConfigManager.shared.overlayEnabled else { return }
        let spaceID = currentSpaceID
        overlayTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            guard let self, self.currentSpaceID == spaceID else { return }
            let index = SpaceManager.shared.activeSpaceIndex() ?? 1
            let name = ConfigManager.shared.displayName(forSpaceID: spaceID, index: index)
            self.overlayPanel.flash(text: name)
        }
    }

    // MARK: - UI

    /// Refreshes both the menu bar title and dropdown menu.
    private func refreshUI() {
        let spaceID = currentSpaceID
        let allSpaces = SpaceManager.shared.allUserSpaceIDs()
        let index = allSpaces.firstIndex(of: spaceID).map({ $0 + 1 }) ?? 1
        let name = ConfigManager.shared.displayName(forSpaceID: spaceID, index: index)

        statusItem.button?.title = name
        buildMenu(allSpaces: allSpaces, activeID: spaceID)
    }

    private func buildMenu(allSpaces: [CGSSpaceID], activeID: CGSSpaceID) {
        let menu = NSMenu()

        let headerItem = NSMenuItem(title: "Desktop Names", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        menu.addItem(.separator())

        for (i, id) in allSpaces.enumerated() {
            let index = i + 1
            let name = ConfigManager.shared.displayName(forSpaceID: id, index: index)
            let prefix = id == activeID ? "● " : "○ "
            let item = NSMenuItem(title: "\(prefix)\(name)", action: #selector(renameDesktop(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = (spaceID: id, index: index)
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let resetItem = NSMenuItem(title: "Reset All Names", action: #selector(resetAllNames), keyEquivalent: "")
        resetItem.target = self
        menu.addItem(resetItem)

        menu.addItem(.separator())

        let overlayItem = NSMenuItem(title: "Show Overlay", action: #selector(toggleOverlay(_:)), keyEquivalent: "")
        overlayItem.target = self
        overlayItem.state = ConfigManager.shared.overlayEnabled ? .on : .off
        menu.addItem(overlayItem)

        let launchItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
        launchItem.target = self
        launchItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(launchItem)

        menu.addItem(.separator())

        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    // MARK: - Actions

    @objc private func renameDesktop(_ sender: NSMenuItem) {
        guard let info = sender.representedObject as? (spaceID: CGSSpaceID, index: Int) else { return }
        let spaceID = info.spaceID
        let index = info.index
        let currentName = ConfigManager.shared.name(forSpaceID: spaceID) ?? ""

        let alert = NSAlert()
        alert.messageText = "Rename Desktop \(index)"
        alert.informativeText = "Enter a name for this desktop (leave blank to reset):"
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        input.stringValue = currentName
        input.placeholderString = "Desktop \(index)"
        alert.accessoryView = input
        alert.window.initialFirstResponder = input

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let newName = input.stringValue.trimmingCharacters(in: .whitespaces)
            ConfigManager.shared.setName(newName.isEmpty ? nil : newName, forSpaceID: spaceID)
            refreshUI()
        }
    }

    @objc private func toggleOverlay(_ sender: NSMenuItem) {
        ConfigManager.shared.setOverlayEnabled(!ConfigManager.shared.overlayEnabled)
        refreshUI()
    }

    @objc private func resetAllNames() {
        let alert = NSAlert()
        alert.messageText = "Reset All Names"
        alert.informativeText = "This will remove all custom desktop names."
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning

        if alert.runModal() == .alertFirstButtonReturn {
            ConfigManager.shared.resetAll()
            refreshUI()
        }
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            let alert = NSAlert(error: error)
            alert.runModal()
        }
        refreshUI()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
