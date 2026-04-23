import AppKit
import Combine
import SwiftUI

final class SpotSettings: ObservableObject {
    static let shared = SpotSettings()
    static let changed = Notification.Name("SpotSettingsChanged")

    // Explicit nonisolated publisher: with SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor, the
    // synthesized @Published wrapper conflicts with ObservableObject's nonisolated
    // requirement, so we drive change notifications manually via willSet.
    nonisolated let objectWillChange = ObservableObjectPublisher()

    private enum Key {
        static let radius = "spot.radius"
        static let opacity = "spot.opacity"
        static let color = "spot.color"
        static let fps = "spot.fps"
        static let clickScale = "spot.clickScale"
        static let minScale = "spot.minScale"
        static let language = "spot.language"
    }

    var radius: Double {
        willSet { objectWillChange.send() }
        didSet { save(Key.radius, radius) }
    }
    var opacity: Double {
        willSet { objectWillChange.send() }
        didSet { save(Key.opacity, opacity) }
    }
    var fps: Double {
        willSet { objectWillChange.send() }
        didSet { save(Key.fps, fps) }
    }
    var clickScale: Double {
        willSet { objectWillChange.send() }
        didSet { save(Key.clickScale, clickScale) }
    }
    var minScale: Double {
        willSet { objectWillChange.send() }
        didSet { save(Key.minScale, minScale) }
    }
    var color: Color {
        willSet { objectWillChange.send() }
        didSet { saveColor(color) }
    }
    var language: String {
        willSet { objectWillChange.send() }
        didSet { save(Key.language, language) }
    }

    var nsColor: NSColor {
        NSColor(color).usingColorSpace(.sRGB) ?? .systemBlue
    }

    private init() {
        let d = UserDefaults.standard
        radius = d.object(forKey: Key.radius) as? Double ?? 14
        opacity = d.object(forKey: Key.opacity) as? Double ?? 0.85
        fps = d.object(forKey: Key.fps) as? Double ?? 60
        clickScale = d.object(forKey: Key.clickScale) as? Double ?? 0.5
        minScale = d.object(forKey: Key.minScale) as? Double ?? 0.2
        language = d.string(forKey: Key.language) ?? Localizer.systemDefault()
        if let rgb = d.array(forKey: Key.color) as? [Double], rgb.count >= 3 {
            color = Color(.sRGB, red: rgb[0], green: rgb[1], blue: rgb[2])
        } else {
            color = Color(.sRGB, red: 0.11, green: 0.63, blue: 1.0)
        }
    }

    private func save<T>(_ key: String, _ value: T) {
        UserDefaults.standard.set(value, forKey: key)
        NotificationCenter.default.post(name: Self.changed, object: nil)
    }

    private func saveColor(_ c: Color) {
        let ns = NSColor(c).usingColorSpace(.sRGB) ?? .white
        save(
            Key.color,
            [Double(ns.redComponent), Double(ns.greenComponent), Double(ns.blueComponent)]
        )
    }
}
