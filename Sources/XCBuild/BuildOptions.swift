import Foundation
import Url

/// Options for xcodebuild's build action:
public struct BuildOptions {
    // MARK: - Init
    public init() {}
    
    // MARK: - Properties
    public var scheme: String? // -scheme
    public var project: Absolute? // -project [sub-type: path]
    
    // If nil XCBuild tries to auto-detect the destination.
    public var destination: Destination? // -destination
    public var destinationTimeout: Int? // -destination-timeout (in seconds)
}
