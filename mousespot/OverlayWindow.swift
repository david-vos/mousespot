import Cocoa

private enum Animation {
    static let tauShrink: Double = 0.064
    static let tauGrow: Double = 0.08
    static let reachedEpsilon: CGFloat = 0.02
    static let holdDuration: Double = 0.8
}

final class OverlayWindow: NSWindow {
    private var timer: Timer?
    private var observer: NSObjectProtocol?
    private var press = PressAnimator()
    
    init() {
        super.init(
            contentRect: Self.frameRect(),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = true
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        
        let view = CircleView()
        view.wantsLayer = true
        contentView = view
        
        observer = NotificationCenter.default.addObserver(
            forName: SpotSettings.changed,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            DispatchQueue.main.async { self?.applySettings() }
        }
    }
    
    deinit {
        observer.map(NotificationCenter.default.removeObserver)
    }
    
    func startTracking() {
        timer?.invalidate()
        let interval = 1.0 / max(1, SpotSettings.shared.fps)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.followCursor()
        }
        orderFront(nil)
    }
    
    func stopTracking() {
        timer?.invalidate()
        timer = nil
        orderOut(nil)
    }
    
    func toggleTracking() {
        timer == nil ? startTracking() : stopTracking()
    }
    
    private static func frameRect() -> NSRect {
        let d = SpotSettings.shared.radius * 2
        return NSRect(x: 0, y: 0, width: d, height: d)
    }
    
    private func applySettings() {
        let rect = Self.frameRect()
        setFrame(NSRect(origin: frame.origin, size: rect.size), display: false)
        contentView?.needsDisplay = true
        if timer != nil { startTracking() }
    }
    
    private func followCursor() {
        guard let event = CGEvent(source: nil),
              let screen = NSScreen.screens.first,
              let circle = contentView as? CircleView
        else { return }
        let s = SpotSettings.shared
        
        // CGEvent uses top-left origin; NSWindow uses bottom-left. Flip Y against primary screen.
        setFrameOrigin(
            NSPoint(
                x: event.location.x - s.radius,
                y: screen.frame.height - event.location.y - s.radius
            )
        )
        
        press.tick(
            pressed: NSEvent.pressedMouseButtons & 1 != 0,
            dt: 1.0 / max(1, s.fps),
            clickScale: CGFloat(s.clickScale),
            minScale: CGFloat(s.minScale)
        )
        circle.scale = press.scale
    }
}

private struct PressAnimator {
    private(set) var scale: CGFloat = 1.0
    private var wasPressed = false
    private var tapLatched = false
    private var holdTime: Double = 0
    
    /// Advances the press animation one frame.
    ///
    /// On a new press the tap is latched: the scale animates to `clickScale` and the latch
    /// only releases once that target is reached, so even sub-frame taps produce a visible
    /// pulse. While the button stays held past the latch, the target eases further toward
    /// `minScale` over `Animation.holdDuration`. On release, it snaps back to 1.0.
    /// Smoothing is frame-rate independent: `k = 1 - exp(-dt / tau)`.
    mutating func tick(pressed: Bool, dt: Double, clickScale: CGFloat, minScale: CGFloat) {
        if pressed && !wasPressed {
            tapLatched = true
            holdTime = 0
        }
        wasPressed = pressed
        
        if tapLatched && scale <= clickScale + Animation.reachedEpsilon {
            tapLatched = false
        }
        
        let target: CGFloat
        if tapLatched {
            target = clickScale
        } else if pressed {
            holdTime += dt
            let t = min(1, holdTime / Animation.holdDuration)
            target = clickScale + (minScale - clickScale) * t
        } else {
            target = 1.0
            holdTime = 0
        }
        
        let tau = target < scale ? Animation.tauShrink : Animation.tauGrow
        let k = 1 - exp(-dt / tau)
        scale += (target - scale) * k
    }
}

private final class CircleView: NSView {
    var scale: CGFloat = 1.0 {
        didSet { needsDisplay = true }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        let s = SpotSettings.shared
        let d = min(bounds.width, bounds.height) * scale
        let rect = NSRect(
            x: (bounds.width - d) / 2,
            y: (bounds.height - d) / 2,
            width: d,
            height: d
        )
        s.nsColor.withAlphaComponent(s.opacity).setFill()
        NSBezierPath(ovalIn: rect).fill()
    }
}
