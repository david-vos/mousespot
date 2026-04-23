import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = SpotSettings.shared
    
    private let labelWidth: CGFloat = 90
    private let controlWidth: CGFloat = 170
    private let valueWidth: CGFloat = 56
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            row(t("size"), value: "\(Int(settings.radius)) pt") {
                Slider(value: $settings.radius, in: 4...40)
            }
            row(t("opacity"), value: "\(Int(settings.opacity * 100))%") {
                Slider(value: $settings.opacity, in: 0...1)
            }
            row(t("color")) {
                ColorPicker("", selection: $settings.color, supportsOpacity: false)
                    .labelsHidden()
            }
            row(t("refresh"), value: "\(Int(settings.fps)) fps") {
                Slider(value: $settings.fps, in: 15...120, step: 1)
            }
            row(t("clickScale"), value: "\(Int(settings.clickScale * 100))%") {
                Slider(value: $settings.clickScale, in: 0.05...1)
            }
            row(t("minScale"), value: "\(Int(settings.minScale * 100))%") {
                Slider(value: $settings.minScale, in: 0.05...1)
            }
            row(t("language")) {
                Picker("", selection: $settings.language) {
                    ForEach(Localizer.supported, id: \.code) { lang in
                        Text(lang.name).tag(lang.code)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(0.08))
        )
        .padding(20)
        .frame(width: 400)
    }
    
    private func row<Control: View>(
        _ title: String,
        value: String = "",
        @ViewBuilder control: () -> Control
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .frame(width: labelWidth, alignment: .leading)
            Spacer(minLength: 0)
            control()
                .frame(width: controlWidth, alignment: .leading)
            Text(value)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: valueWidth, alignment: .trailing)
        }
    }
}
