import Foundation
import Url

// MARK: - Result Types
public typealias AbsoluteResult = Result<Absolute>
public typealias DataResult = Result<Data>
public typealias StringResult = Result<String>
public typealias MetadataResult = Result<Metadata>
public typealias DirectoryResult = Result<[Absolute]>

/// File System Access
/// The File System API is kinda ugly: Crazy names, everything can fail and returns a Result-type.
/// This is because in reality every FS-operation can actually fail.
/// Even though the API is ugly there is a extension on FileSystem down below which exposes a nicer
/// API. The nicer API is throwing errors if something goes wrong and has better names.
/// However: Even with the "nice"-API this whole construct feels kinda strange and should be redone
/// better sooner than later. 😂
public protocol FileSystem: AnyObject {
    // MARK: - Getting Global Urls
    func homeDirectoryUrlResult() -> AbsoluteResult
    func temporaryDirectoryUrlResult() -> AbsoluteResult
    func uniqueTemporaryDirectoryUrlResult() -> AbsoluteResult
    
    // MARK: - Creating Files & Directories
    @discardableResult func createDirectoryResult(at url: Absolute) -> AbsoluteResult
    @discardableResult func writeDataResult(_ data: Data, to url: Absolute) -> AbsoluteResult
    @discardableResult func writeStringResult(_ string: String, to url: Absolute) -> AbsoluteResult

    // MARK: - Getting Files, Directories & Metadata
    func dataResult(at url: Absolute) -> DataResult
    func directoryContentsResult(at url: Absolute) -> DirectoryResult
    func itemMetadataResult(at url: Absolute) -> MetadataResult
    func directory(at url: Absolute) -> Directory
    func file(at url: Absolute) -> File
    func stringContentsResult(at url: Absolute) -> StringResult

    // MARK: - Deleting Files & DIrectories
    @discardableResult func deleteItemResult(at url: Absolute) -> AbsoluteResult
    @discardableResult func deleteResult(file: Absolute) -> AbsoluteResult
    @discardableResult func deleteResult(directory: Absolute) -> AbsoluteResult
    
    // MARK: - Validating Files & Directories
    func assertItem(at url: Absolute, `is` itemType: Metadata) throws
}

// MARK: - Error-based FileSystem-API
extension FileSystem {
    // MARK: - Getting Global Urls
    public func homeDirectoryUrl() throws -> Absolute {
        return try homeDirectoryUrlResult().dematerialize()
    }
    public func temporaryDirectoryUrl() throws -> Absolute {
        return try temporaryDirectoryUrlResult().dematerialize()
    }
    public func uniqueTemporaryDirectoryUrl() throws -> Absolute {
        return try uniqueTemporaryDirectoryUrlResult().dematerialize()
    }
    
    // MARK: - Primitives for reading, writing and creating directories
    public func createDirectory(at url: Absolute) throws {
        try createDirectoryResult(at: url).assertSuccess()
    }
    public func writeData(_ data: Data, to url: Absolute) throws {
        try writeDataResult(data, to: url).assertSuccess()
    }
    public func data(at url: Absolute) throws -> Data {
        return try dataResult(at: url).dematerialize()
    }
    public func stringContents(at url: Absolute) throws -> String {
        return try stringContentsResult(at: url).dematerialize()
    }
    public func dataContents(at url: Absolute) throws -> Data {
        return try dataResult(at: url).dematerialize()
    }
    
    // MARK: - Deleting
    public func deleteItem(at url: Absolute) throws {
        try deleteItemResult(at: url).assertSuccess()
    }
    @discardableResult public func delete(file: Absolute) throws -> Absolute {
        return try deleteResult(file: file).dematerialize()
    }
    @discardableResult public func delete(directory: Absolute) throws -> Absolute {
        return try deleteResult(directory: directory).dematerialize()
    }
    
    // MARK: - Metadata
    public func itemMetadata(at url: Absolute) throws -> Metadata {
        return try itemMetadataResult(at: url).dematerialize()
    }
    
    // MARK: - Getting Directories
    public func directoryContents(at url: Absolute) throws -> [Absolute] {
        return try directoryContentsResult(at: url).dematerialize()
    }
}

public enum Metadata {
    case directory, file
}

// MARK: - FileSystem Defaults
extension FileSystem {
    // Primitives
    @discardableResult
    public func writeStringResult(_ string: String, to url: Absolute) -> AbsoluteResult {
        guard let data = string.data(using: .utf8) else {
            return .failure(.other("Failed to convert data to utf8 string."))
        }
        return writeDataResult(data, to: url)
    }
    
    public func writeString(_ string: String, to url: Absolute) throws {
        return try writeStringResult(string, to: url).assertSuccess()
    }
    
    // Convenience
    @discardableResult
    public func deleteResult(file url: Absolute) -> AbsoluteResult {
        guard file(at: url).isExistingFile else { return .failure(.doesNotExist) }
        return deleteItemResult(at: url)
    }
    
    @discardableResult
    public func deleteResult(directory url: Absolute) -> AbsoluteResult {
        guard directory(at: url).isExistingDirectory else { return .failure(.doesNotExist) }
        return deleteItemResult(at: url)
    }
    
    public func file(at url: Absolute) -> File {
        return File(url: url, fileSystem: self)
    }
    
    public func directory(at url: Absolute) -> Directory {
        return Directory(url: url, in: self)
    }
    
    public func stringContentsResult(at url: Absolute) -> StringResult {
        do {
            return .success(try file(at: url).string())
        } catch {
            return .failure(.other(error))
        }
    }

    public func assertItem(at url: Absolute, is itemType: Metadata) throws {
        let meta = try itemMetadata(at: url)
        let actualType = meta
        let actualVsExpected = (actualType, itemType)
        switch actualVsExpected {
        case let(actual, expected) where actual == expected: return
        default: throw Error.typeMismatch
        }
    }
    
    public func uniqueTemporaryDirectoryUrlResult() -> AbsoluteResult {
        let unique = temporaryDirectoryUrlResult().map { $0.appending(UUID().uuidString) }
        let createDirResult = unique.map { createDirectoryResult(at: $0) }
        return createDirResult
    }
}

