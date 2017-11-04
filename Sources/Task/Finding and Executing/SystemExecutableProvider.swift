import Foundation
import FileSystem
import Url

public final class SystemExecutableProvider {
    // MARK: - Init
    public init(searchedUrls: [Absolute], fileSystem: FileSystem) {
        searchPathsProvider = SearchPathsExecutableProvider(searchPaths: searchedUrls, fileSystem: fileSystem)
        group.add(searchPathsProvider)
    }
    
    // MARK: - Convenience
    public static func local() -> SystemExecutableProvider {
        let urls = PathEnvironmentParser.local().urls
        let fs = LocalFileSystem()
        return SystemExecutableProvider(searchedUrls: urls, fileSystem: fs)
    }
    
    // MARK: - Properties
    public var searchedUrls: [Absolute] {
        get { return searchPathsProvider.searchPaths }
        set { searchPathsProvider.searchPaths = newValue }
    }
    
    public var fileSystem: FileSystem {
        return searchPathsProvider.fileSystem
    }

    private let group = ExecutableProviderGroup()
    private let searchPathsProvider: SearchPathsExecutableProvider
    
    // MARK: - Working with the Group
    public func add(_ provider: ExecutableProvider) {
        group.add(provider)
    }
}

extension SystemExecutableProvider: ExecutableProvider {
    public func urlForExecuable(_ executableName: String) -> Absolute? {
        return group.urlForExecuable(executableName)
    }
}

private final class SearchPathsExecutableProvider {
    // MARK: - Init
    init(searchPaths: [Absolute], fileSystem: FileSystem) {
        self.searchPaths = searchPaths
        self.fileSystem = fileSystem
    }
    
//    // MARK: - Convenience
//    public static func local() -> SystemExecutableProvider {
//        let urls = PathEnvironmentParser.local().urls
//        let fs = LocalFileSystem()
//        return SystemExecutableProvider(searchedUrls: urls, fileSystem: fs)
//    }
    
    // MARK: - Properties
    var searchPaths = [Absolute]()
    let fileSystem: FileSystem
}

extension SearchPathsExecutableProvider: ExecutableProvider {
    public func urlForExecuable(_ executableName: String) -> Absolute? {
        for url in searchPaths {
            let potentialUrl = url.appending(executableName)
            let executableFound = fileSystem.file(at: potentialUrl).isExistingFile
            guard executableFound else { continue }
            return Absolute(potentialUrl.path)
        }
        return nil
    }
}
