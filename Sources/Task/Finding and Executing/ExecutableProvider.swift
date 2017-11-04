import Foundation
import Url

/// Maps names command line tools/executables to file urls.
/// The protcol is implemented in a different frameworok.
public protocol ExecutableProvider {
    func urlForExecuable(_ executableName: String) -> Absolute?
}

open class ExecutableProviderGroup {
    // MARK: - Init
    public init() {}
    
    // MARK: - Properties
    public private(set) var providers = [ExecutableProvider]()
    
    // MARK: - Working with the Group
    public func add(_ provider: ExecutableProvider) {
        providers.append(provider)
    }
}

extension ExecutableProviderGroup: ExecutableProvider {
    public func urlForExecuable(_ executableName: String) -> Absolute? {
        for provider in providers {
            if let url = provider.urlForExecuable(executableName) {
                return url
            }
        }
        return nil
    }
}
