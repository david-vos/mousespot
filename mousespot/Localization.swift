import Foundation

struct LanguageOption {
    let code: String
    let name: String
}

enum Localizer {
    static let supported: [LanguageOption] = [
        LanguageOption(code: "en", name: "English"),
        LanguageOption(code: "nl", name: "Nederlands"),
        LanguageOption(code: "de", name: "Deutsch"),
        LanguageOption(code: "fr", name: "Français"),
    ]

    private static let table: [String: [String: String]] = load()

    static func t(_ key: String) -> String {
        let lang = SpotSettings.shared.language
        return table[lang]?[key]
            ?? table["en"]?[key]
            ?? key
    }

    static func systemDefault() -> String {
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        return supported.contains { $0.code == code } ? code : "en"
    }

    private static func load() -> [String: [String: String]] {
        guard let url = Bundle.main.url(forResource: "Strings", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let parsed = try? JSONDecoder().decode([String: [String: String]].self, from: data)
        else { return [:] }
        return parsed
    }
}

func t(_ key: String) -> String { Localizer.t(key) }
