import Foundation
import Url

/// Options for xcodebuild's archive action:
public struct ArchiveOptions {
    // MARK: - Init
    public init() {}
    
    // MARK: - Properties
    public var scheme: String? // -scheme
    public var project: Absolute? // -project [sub-type: path]
    
    // -destination
    public var destination: Destination?
    
    public var platform = ArchivePlatform.iOS
    // Option: -archivePath
    // Type: path
    // Notes: Directory at archivePath must not exist already.
    public var archivePath: Absolute?
    
    public var logDestination = LogDestination.standardStream
}

public enum ArchivePlatform: String {
    case macOS, iOS, tvOS
}

public enum LogDestination {
    case standardStream
    case file(Absolute)
}
