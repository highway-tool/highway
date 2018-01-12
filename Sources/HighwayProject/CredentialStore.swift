import Foundation
import Keychain
import Errors

public protocol CredentialStore {
    func password() -> String?
    func setPassword(_ password: String) throws
    func user() -> String?
    func setUser(_ user: String)
}

public class LocalCredentialStore {
    // MARK: - Init
    public init(keychain: Keychain) {
        self.keychain = keychain
    }
    // MARK: - Properties
    private let keychain: Keychain
    private var _user: String?
    private var _password: String?
}

extension LocalCredentialStore: CredentialStore {
    public func password() -> String? {
        guard let user = _user, user.isEmpty == false else {
            return nil
        }
        return try? keychain.passwordFor(account: user, server: prefixedServer(with: user))
    }
    
    public func setPassword(_ password: String) throws {
        guard let user = _user, user.isEmpty == false else {
            throw "User missing"
        }
        _password = password
        try keychain.add(password: password, account: user, server:  prefixedServer(with: user))
    }
    
    public func user() -> String? {
        return _user
    }
    
    public func setUser(_ user: String) {
        _user = user
    }
    
    // MARK: - Helper
    private func prefixedServer(with user: String) -> String {
        return "highway." + user
    }
}
