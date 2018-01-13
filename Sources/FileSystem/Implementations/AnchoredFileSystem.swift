import Foundation
import Url

public final class AnchoredFileSystem {
    // MARK: - Init
    public init(underlyingFileSystem: FileSystem, achnoredAt root: Absolute) {
        self.underlyingFileSystem = underlyingFileSystem
        self.root = root
    }
    
    // MARL: Properties
    public let underlyingFileSystem: FileSystem
    public let root: Absolute
}

extension AnchoredFileSystem: FileSystem {
    public func directoryContentsResult(at url: Absolute) -> DirectoryResult {
        return underlyingFileSystem.directoryContentsResult(at: _completeUrl(url))
    }
    
    public func assertItem(at url: Absolute, is itemType: Metadata) throws {
        let meta = try itemMetadata(at: url)
        guard meta == itemType else {
            throw Error.typeMismatch
        }
    }
    public func itemMetadataResult(at url: Absolute) -> MetadataResult {
        return underlyingFileSystem.itemMetadataResult(at: _completeUrl(url))
    }
    
    public func homeDirectoryUrlResult() -> AbsoluteResult {
        return underlyingFileSystem.homeDirectoryUrlResult()
    }
    
    public func temporaryDirectoryUrlResult() -> AbsoluteResult {
        return underlyingFileSystem.temporaryDirectoryUrlResult()
    }
    
    @discardableResult
    public func createDirectoryResult(at url: Absolute) -> AbsoluteResult {
        return underlyingFileSystem.createDirectoryResult(at: _completeUrl(url))
    }
    
    @discardableResult
    public func writeDataResult(_ data: Data, to url: Absolute) -> AbsoluteResult {
        return underlyingFileSystem.writeDataResult(data, to: _completeUrl(url))
    }
    
    public func dataResult(at url: Absolute) -> DataResult {
        return underlyingFileSystem.dataResult(at: _completeUrl(url))
    }
    
    @discardableResult
    public func deleteItemResult(at url: Absolute) -> AbsoluteResult {
        return underlyingFileSystem.deleteItemResult(at: _completeUrl(url))
    }
    public func writeString(_ string: String, to url: Absolute) throws {
        guard let data = string.data(using: .utf8) else {
            throw Error.other("Failed to convert data to utf8 string.")
        }
        try writeData(data, to: url)
    }

    // MARK: - Convenience
    public func file(at url: Absolute) -> File {
        return File(url: url, fileSystem: self)
    }
    
    public func directory(at url: Absolute) -> Directory {
        return Directory(url: url, in: self)
    }
    
    public func stringContents(at url: Absolute) throws -> String {
        return try file(at: _completeUrl(url)).string()
    }
    
    public func dataContents(at url: Absolute) throws -> Data {
        return try file(at: _completeUrl(url)).data()
    }
    
    private func _completeUrl(_ proposedUrl: Absolute) -> Absolute {
        if proposedUrl == Absolute.root {
            return root
        } else {
            let relativePath = proposedUrl.asRelativePath
            return Absolute(path: relativePath, relativeTo: root)
        }
    }
}

