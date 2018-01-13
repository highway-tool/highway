import Foundation
import Url

public class LocalFileSystem: FileSystem {
    public func directoryContentsResult(at url: Absolute) -> DirectoryResult {
        let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants]
        do {
            let urls = try _fm.contentsOfDirectory(at: url.url,
                                                   includingPropertiesForKeys: nil,
                                                   options: options)
            return .success(urls.map { Absolute($0) })
        } catch {
            return .failure(error.asFSError)
        }
    }
    
    // MARK: - Init
    public init() {}
    
    // MARK: - Properties
    private let _fm = FileManager()

    // MARK: - FileSystem
    public func homeDirectoryUrlResult() -> AbsoluteResult {
        return AbsoluteResult(Absolute(NSHomeDirectory()))
    }
    
    public func temporaryDirectoryUrlResult() -> AbsoluteResult {
        return AbsoluteResult(Absolute(NSTemporaryDirectory()))
    }
    
    @discardableResult
    public func deleteItemResult(at url: Absolute) -> AbsoluteResult {
        return _fm.removeItem(at: url)
    }
    
    @discardableResult
    public func createDirectoryResult(at url: Absolute) -> AbsoluteResult {
        do {
            try _fm.createDirectory(atAbsolute: url, withIntermediateDirectories: true)
            return AbsoluteResult(url)
        } catch {
            return AbsoluteResult(error.asFSError)
        }
    }

    @discardableResult
    public func writeDataResult(_ data: Data, to url: Absolute) -> AbsoluteResult {
        return data.write(to: url)
    }
    
    public func dataResult(at url: Absolute) -> DataResult {
        return Data.data(contentsOf: url)
    }
    
    public func itemMetadataResult(at url: Absolute) -> MetadataResult {
        var isDir = ObjCBool(false)
        guard _fm.fileExists(atPath: url.path, isDirectory: &isDir) else {
            return .failure(.doesNotExist)
        }
        return .success(isDir.boolValue ? .directory : .file)
    }
}

extension Swift.Error {
    var asFSError: Error {
        guard let cocoaError = self as? CocoaError  else {
            return .other(self)
        }
        
        let notFoundCodes: Set<CocoaError.Code> = [.fileNoSuchFile, .fileReadNoSuchFile]
        if notFoundCodes.contains(cocoaError.code) {
            return .doesNotExist
        }
        return .other(self)
    }
}

extension Data {
    // MARK: - Init
    static func data(contentsOf url: Absolute) -> Result<Data> {
        do {
            return .success(try self.init(contentsOf: url.url))
        } catch {
            return .failure(error.asFSError)
        }
    }
    
    // MARK: - Writing
    func write(to url: Absolute) -> AbsoluteResult {
        do {
            try write(to: url.url)
            return AbsoluteResult(url)
        } catch {
            return AbsoluteResult(error.asFSError)
        }
    }
}

// MARK: - FileManager Support for Absolute, so that we do not have to expose a URL.
extension FileManager {
    func removeItem(at url: Absolute) -> AbsoluteResult {
        do {
            try removeItem(at: url.url)
            return AbsoluteResult(url)
        } catch {
            return AbsoluteResult(error.asFSError)
        }
    }
    func createDirectory(atAbsolute url: Absolute, withIntermediateDirectories createIntermediates: Bool) throws {
        try createDirectory(at: url.url, withIntermediateDirectories: createIntermediates, attributes: nil)
    }
}

