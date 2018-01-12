import Foundation
import Url

public protocol Deliver {
    func now(with options: Options) throws
}

public struct Options {
    // MARK: - Init
    public init(ipaUrl: Absolute, username: String, password: Password, platform: Platform = .iOS) {
        self.ipaUrl = ipaUrl
        self.username = username
        self.password = password
        self.platform = platform
    }
    
    // MARK: - Properties
    public let ipaUrl: Absolute
    public let platform: Platform
    public let username: String // apple id username
    public let password: Password
}

public final class Local: Deliver {
    // MARK: - Init
    public init(altool: Altool) {
        self.altool = altool
    }
    
    // MARK: - Properties
    private let altool: Altool
    
    // MARK: - Deliver Implementation
    public func now(with options: Options) throws {
        let alOptions = Altool.Options(action: .upload, file: options.ipaUrl, type: options.platform, username: options.username, password: options.password, outputFormat: .normal)
        try altool.execute(with: alOptions).assertSuccess()
    }
}

/// Also used by Altool
public enum Platform: String {
    case macOS = "osx"
    case iOS = "ios"
    case tvOS = "appletvos"
}

/// Also used by Altool
public enum Password {
    case plain(String) // value: plain password
    case keychainItem(named: String)
    case environment(named: String)
}

