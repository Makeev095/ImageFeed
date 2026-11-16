import Foundation
import SwiftKeychainWrapper

final class OAuth2TokenStorage {
    static let shared = OAuth2TokenStorage()
    private init() {}

    private enum Keys {
        static let token = "OAuth2Token"
    }

    var token: String? {
        get {
            KeychainWrapper.standard.string(forKey: Keys.token)
        }
        set {
            if let newValue {
                KeychainWrapper.standard.set(newValue, forKey: Keys.token)
            } else {
                KeychainWrapper.standard.removeObject(forKey: Keys.token)
            }
        }
    }
}
