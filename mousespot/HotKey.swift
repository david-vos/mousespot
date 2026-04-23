import AppKit
import Carbon.HIToolbox

nonisolated(unsafe) private var handlers: [UInt32: () -> Void] = [:]
nonisolated(unsafe) private var nextID: UInt32 = 1
nonisolated(unsafe) private var handlerInstalled = false

private let hotKeySignature: OSType = 0x4D53_5054  // 'MSPT'

private func hotKeyCallback(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    var id = EventHotKeyID()
    GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &id
    )
    handlers[id.id]?()
    return noErr
}

/// Registers a system-wide hotkey via Carbon's `RegisterEventHotKey`.
///
/// Carbon is used instead of `NSEvent.addGlobalMonitor` because it works under App Sandbox
/// without requiring Accessibility permission. The C event handler cannot capture Swift
/// context, so dispatch goes through a module-level `handlers` dictionary keyed by id.
final class HotKey {
    private var ref: EventHotKeyRef?
    
    init(keyCode: UInt32, modifiers: UInt32, handler: @escaping @MainActor () -> Void) {
        Self.installHandlerOnce()
        
        let id = nextID
        nextID += 1
        handlers[id] = { MainActor.assumeIsolated(handler) }
        
        var r: EventHotKeyRef?
        RegisterEventHotKey(
            keyCode,
            modifiers,
            EventHotKeyID(signature: hotKeySignature, id: id),
            GetApplicationEventTarget(),
            0,
            &r
        )
        ref = r
    }
    
    deinit {
        if let ref { UnregisterEventHotKey(ref) }
    }
    
    private static func installHandlerOnce() {
        guard !handlerInstalled else { return }
        handlerInstalled = true
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(GetApplicationEventTarget(), hotKeyCallback, 1, &spec, nil, nil)
    }
}
