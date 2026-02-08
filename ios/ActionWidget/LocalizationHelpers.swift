import Foundation

struct LocalizationHelpers {
    static func getAppLanguage() -> String {
        let groupDefaults = UserDefaults(suiteName: "group.com.pooha302.didit")
        var lang = groupDefaults?.string(forKey: "language_code") ?? "system"
        
        if lang == "system" {
            lang = Locale.current.language.languageCode?.identifier ?? "en"
        }
        return lang
    }
    
    static func localizedString(_ key: String) -> String {
        let lang = getAppLanguage()
        
        // Try to find the bundle for the language
        if let path = Bundle.main.path(forResource: lang, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return NSLocalizedString(key, tableName: nil, bundle: bundle, value: key, comment: "")
        }
        
        // Fallback to English
        if let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
           let bundle = Bundle(path: path) {
             return NSLocalizedString(key, tableName: nil, bundle: bundle, value: key, comment: "")
        }
        
        // Fallback to standard
        return NSLocalizedString(key, comment: "")
    }
}
