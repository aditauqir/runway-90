import Foundation

/// Reads optional credentials from Secrets.plist (bundled, git-ignored).
/// Every integration must degrade to a labelled demo fallback when a key is missing.
enum Secrets {
    private static let dict: [String: String] = {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String]
        else { return [:] }
        return plist
    }()

    static var geminiAPIKey: String?      { nonEmpty("GEMINI_API_KEY") }
    static var backboardAPIKey: String?   { nonEmpty("BACKBOARD_API_KEY") }
    static var tigerDataURL: String?      { nonEmpty("TIGER_DATA_URL") }        // full postgres:// connection string to Tiger Cloud
    static var auth0Domain: String?       { nonEmpty("AUTH0_DOMAIN") }
    static var auth0ClientId: String?     { nonEmpty("AUTH0_CLIENT_ID") }

    private static func nonEmpty(_ key: String) -> String? {
        guard let v = dict[key], !v.isEmpty, !v.hasPrefix("YOUR_") else { return nil }
        return v
    }
}
