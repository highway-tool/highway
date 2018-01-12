import Foundation
import Security
import Task
import Arguments

public protocol Keychain {
    // MARK: - Working with the Keychain
    func add(password: String, account: String, server: String) throws
    func passwordFor(account: String, server: String) throws -> String
}
