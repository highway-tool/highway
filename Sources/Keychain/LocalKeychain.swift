import Foundation
import Security
import Task
import Arguments

public class LocalKeychain {
    // MARK: - Init
    public init(system: System) {
        self.system = system
    }
    
    // MARK: - Properties
    public let system: System
    
    // MARK: - Helper
    private func _security() throws -> Task {
        return try system.task(named: "security").dematerialize()
    }
}

extension LocalKeychain: Keychain {
    public func add(password: String, account: String, server: String) throws {
        let task = try _security()
        
        task.arguments = [
            "add-internet-password",
            "-a", account,
            "-s", server,
            "-w"]
        task.arguments += SecureString(password)
        try system.execute(task).assertSuccess()
    }
    
    public func passwordFor(account: String, server: String) throws -> String  {
        let task = try _security()
        task.arguments = [
            "find-internet-password",
            "-a", account,
            "-s", server,
            "-w" // Display only the password on stdout
        ]
        
        task.enableReadableOutputDataCapturing()
        try system.execute(task).assertSuccess()
        
        guard let password = task.trimmedOutput, password.isEmpty == false else {
            throw "Failed to get password from keychain: No Output found."
        }
        
        return password
        
    }
}
