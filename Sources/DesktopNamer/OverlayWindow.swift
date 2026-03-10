import Cocoa

/// A translucent HUD-style overlay that briefly flashes the desktop name when switching spaces.
final class OverlayPanel: NSPanel {
    private let label = NSTextField(labelWithString: "")

    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(contentRect: contentRect, styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered, defer: false)
        configure()
    }

    private func configure() {
        level = .floating
        isOpaque = false
        hasShadow = false
        backgroundColor = .clear
        ignoresMouseEvents = true
        collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        isMovableByWindowBackground = false

        // Light rounded-rect background
        let backdrop = NSVisualEffectView()
        backdrop.material = .menu
        backdrop.state = .active
        backdrop.blendingMode = .behindWindow
        backdrop.wantsLayer = true
        backdrop.layer?.cornerRadius = 20
        backdrop.layer?.masksToBounds = true

        contentView = backdrop

        // Label
        label.font = NSFont.systemFont(ofSize: 36, weight: .medium)
        label.textColor = .labelColor
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        backdrop.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: backdrop.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: backdrop.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: backdrop.leadingAnchor, constant: 32),
            label.trailingAnchor.constraint(lessThanOrEqualTo: backdrop.trailingAnchor, constant: -32),
        ])
    }

    // MARK: - Public

    private var hideTimer: Timer?

    /// Instantly hides the overlay, cancelling any pending animations.
    func cancelAndHide() {
        hideTimer?.invalidate()
        hideTimer = nil
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0
            self.animator().alphaValue = 0
        }
        orderOut(nil)
    }

    func flash(text: String, duration: TimeInterval = 1.2) {
        hideTimer?.invalidate()

        label.stringValue = text

        // Size the window to fit the text
        let textSize = (text as NSString).size(withAttributes: [.font: label.font!])
        let width = max(textSize.width + 80, 200)
        let height: CGFloat = 80

        guard let screen = NSScreen.main else { return }
        let x = screen.frame.midX - width / 2
        let y = screen.visibleFrame.maxY - height - 16
        setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)

        alphaValue = 0
        orderFrontRegardless()

        // Fade in
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            self.animator().alphaValue = 1.0
        }

        // Schedule fade out
        hideTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.4
                self?.animator().alphaValue = 0
            }, completionHandler: {
                self?.orderOut(nil)
            })
        }
    }
}
