import Foundation

final class OAuth2TokenStorage {
    private let userDefaults = UserDefaults.standard

    private enum Keys {
        static let token = "OAuth2Token"
    }

    var token: String? {
        get {
            userDefaults.string(forKey: Keys.token)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.token)
        }
    }
}
