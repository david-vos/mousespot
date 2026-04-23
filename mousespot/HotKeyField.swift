import AppKit
import Carbon.HIToolbox
import SwiftUI

struct HotKeyField: NSViewRepresentable {
    @Binding var keyCode: UInt32
    @Binding var modifiers: UInt32

    func makeNSView(context: Context) -> HotKeyCaptureView {
        let view = HotKeyCaptureView()
        view.onCapture = { code, mods in
            keyCode = code
            modifiers = mods
        }
        view.refresh(keyCode: keyCode, modifiers: modifiers)
        return view
    }

    func updateNSView(_ nsView: HotKeyCaptureView, context: Context) {
        nsView.refresh(keyCode: keyCode, modifiers: modifiers)
    }
}

final class HotKeyCaptureView: NSView {
    var onCapture: ((UInt32, UInt32) -> Void)?

    private let label = NSTextField(labelWithString: "")
    private var capturing = false {
        didSet { needsDisplay = true; updateLabel() }
    }
    private var currentCode: UInt32 = 0
    private var currentMods: UInt32 = 0

    override var acceptsFirstResponder: Bool { true }
    override var isFlipped: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        label.alignment = .center
        label.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        label.isEditable = false
        label.isSelectable = false
        label.drawsBackground = false
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightAnchor.constraint(equalToConstant: 24),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func refresh(keyCode: UInt32, modifiers: UInt32) {
        currentCode = keyCode
        currentMods = modifiers
        updateLabel()
    }

    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 5, yRadius: 5)
        (capturing ? NSColor.selectedControlColor : NSColor.controlBackgroundColor).setFill()
        path.fill()
        NSColor.separatorColor.setStroke()
        path.stroke()
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        capturing = true
    }

    override func becomeFirstResponder() -> Bool {
        let ok = super.becomeFirstResponder()
        if !ok { capturing = false }
        return ok
    }

    override func resignFirstResponder() -> Bool {
        capturing = false
        return super.resignFirstResponder()
    }

    override func keyDown(with event: NSEvent) {
        guard capturing else { super.keyDown(with: event); return }
        if event.keyCode == UInt16(kVK_Escape) {
            capturing = false
            window?.makeFirstResponder(nil)
            return
        }
        let mods = Self.carbonModifiers(from: event.modifierFlags)
        // Require at least one modifier so plain letters don't steal typing.
        guard mods != 0 else { NSSound.beep(); return }
        let code = UInt32(event.keyCode)
        currentCode = code
        currentMods = mods
        onCapture?(code, mods)
        capturing = false
        window?.makeFirstResponder(nil)
    }

    private func updateLabel() {
        if capturing {
            label.stringValue = t("hotkeyRecording")
            label.textColor = .selectedControlTextColor
        } else {
            label.stringValue = Self.describe(keyCode: currentCode, modifiers: currentMods)
            label.textColor = .labelColor
        }
    }

    static func appKitModifiers(from carbon: UInt32) -> NSEvent.ModifierFlags {
        var out: NSEvent.ModifierFlags = []
        if carbon & UInt32(cmdKey) != 0 { out.insert(.command) }
        if carbon & UInt32(optionKey) != 0 { out.insert(.option) }
        if carbon & UInt32(controlKey) != 0 { out.insert(.control) }
        if carbon & UInt32(shiftKey) != 0 { out.insert(.shift) }
        return out
    }

    /// Lowercase single-character key equivalent for NSMenuItem. Empty for non-character keys.
    static func menuKeyEquivalent(for keyCode: UInt32) -> String {
        if specialKeys[Int(keyCode)] != nil { return "" }
        let name = keyName(keyCode)
        return name.count == 1 ? name.lowercased() : ""
    }

    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var out: UInt32 = 0
        if flags.contains(.command) { out |= UInt32(cmdKey) }
        if flags.contains(.option) { out |= UInt32(optionKey) }
        if flags.contains(.control) { out |= UInt32(controlKey) }
        if flags.contains(.shift) { out |= UInt32(shiftKey) }
        return out
    }

    static func describe(keyCode: UInt32, modifiers: UInt32) -> String {
        var s = ""
        if modifiers & UInt32(controlKey) != 0 { s += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { s += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { s += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { s += "⌘" }
        s += keyName(keyCode)
        return s
    }

    private static func keyName(_ code: UInt32) -> String {
        if let special = specialKeys[Int(code)] { return special }
        // Translate using current keyboard layout.
        let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue()
        guard let source,
              let layoutDataRaw = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
        else { return "?" }
        let layoutData = Unmanaged<CFData>.fromOpaque(layoutDataRaw).takeUnretainedValue() as Data
        var deadKeyState: UInt32 = 0
        var chars: [UniChar] = [0, 0, 0, 0]
        var length = 0
        let status = layoutData.withUnsafeBytes { raw -> OSStatus in
            guard let ptr = raw.baseAddress?.assumingMemoryBound(to: UCKeyboardLayout.self) else {
                return -1
            }
            return UCKeyTranslate(
                ptr,
                UInt16(code),
                UInt16(kUCKeyActionDisplay),
                0,
                UInt32(LMGetKbdType()),
                OptionBits(kUCKeyTranslateNoDeadKeysBit),
                &deadKeyState,
                chars.count,
                &length,
                &chars
            )
        }
        guard status == noErr, length > 0 else { return "?" }
        return String(utf16CodeUnits: chars, count: length).uppercased()
    }

    private static let specialKeys: [Int: String] = [
        kVK_Space: "Space",
        kVK_Return: "↩",
        kVK_Tab: "⇥",
        kVK_Delete: "⌫",
        kVK_ForwardDelete: "⌦",
        kVK_Escape: "⎋",
        kVK_LeftArrow: "←",
        kVK_RightArrow: "→",
        kVK_UpArrow: "↑",
        kVK_DownArrow: "↓",
        kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4",
        kVK_F5: "F5", kVK_F6: "F6", kVK_F7: "F7", kVK_F8: "F8",
        kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12",
    ]
}
