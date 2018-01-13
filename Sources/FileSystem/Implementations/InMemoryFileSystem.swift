import Foundation
import Url

typealias Node = InMemoryFileSystem.Node
typealias DirectoryContents = InMemoryFileSystem.Node.DirectoryContents

public final class InMemoryFileSystem: FileSystem {
    public func directoryContentsResult(at url: Absolute) -> DirectoryResult {
        do {
            guard let node = try getNode(url) else {
                return .failure(.doesNotExist)
            }
            guard let dir = node.contents.directoryContents else {
                return .failure(.doesNotExist)
            }
            return .success(dir.entries.keys.map { url.appending($0) })
        } catch {
            return .failure(.other(error))
        }
    }
    
    public func itemMetadataResult(at url: Absolute) -> MetadataResult {
        do {
            guard try nodeExists(at: url) else {
                return .failure(.doesNotExist)
            }
            
            guard let node = try getNode(url) else {
                return .failure(.doesNotExist)
            }
            
            switch node.contents {
            case .file(_):
                return .success(.file)
            case .directory(_):
                return .success(.directory)
            }
        } catch {
            return .failure(.other(error))
        }
        
    }
    
    public func deleteItemResult(at url: Absolute) -> AbsoluteResult {
        do {
            let parentUrl = url.parent
            guard let parentNode = try getNode(parentUrl) else {
                return .failure(.doesNotExist)
            }
            parentNode[url.lastPathComponent] = nil
            return .success(url)
        } catch {
            return .failure(.other(error))
        }
    }
    
    public func homeDirectoryUrlResult() -> AbsoluteResult {
        return AbsoluteResult(homeDirectoryUrlOverride)
    }
    
    public func temporaryDirectoryUrlResult() -> AbsoluteResult {
        return AbsoluteResult(temporaryDirectoryUrlOverride)
    }
    
    @discardableResult
    public func createDirectoryResult(at url: Absolute) -> AbsoluteResult {
        let urlsToUrl:[Absolute] = [.root] + url.urlsFromRootToSelf.remainingUrls
        for directoryURL in urlsToUrl {
            do {
            if try nodeExists(at: directoryURL) == true {
                continue
            }
            let currentParentURL = directoryURL.parent
                guard let currentParent = try getNode(currentParentURL) else {
                    return AbsoluteResult(.doesNotExist)
                }
                currentParent[directoryURL.lastPathComponent] = .directory()
            } catch {
                return AbsoluteResult(.doesNotExist)
            }
        }
        return AbsoluteResult(url)
    }
    
    @discardableResult
    public func writeDataResult(_ data: Data, to url: Absolute) -> AbsoluteResult {
        do {
            let tailURL = url.parent
            guard let node = try getNode(tailURL) else {
                return AbsoluteResult(.other("write to file failed because it has no parent."))
            }
            node[url.lastPathComponent] = .file(String(data: data, encoding: .utf8)!)
            return AbsoluteResult(url)
        } catch {
            return AbsoluteResult(.other(error))
        }
    }
    
    public func dataResult(at url: Absolute) -> DataResult {
        do {
            guard let node = try getNode(url) else {
                return .failure(.doesNotExist)
            }
            guard let string = node.contents.fileContents else {
                return .failure(.doesNotExist)
            }
            guard let contents = string.data(using: .utf8) else {
                return .failure(.other("File '\(url)': Has content but conversion to Data failed."))
            }
            return DataResult(contents)
        } catch {
            return .failure(.other(error))
        }
        
    }
    
    // MARK: - Properties
    public var root: Node
    public var homeDirectoryUrlOverride = Absolute.root
    public var temporaryDirectoryUrlOverride = Absolute.root

    
    // MARK: - Init
    public init() {
        self.root = Node(.directory(DirectoryContents(entries: [:])))
    }

    private func nodeExists(at url: Absolute) throws -> Bool {
        return try getNode(url) != nil
    }

    private func getNode(_ url: Absolute) throws -> Node? {
        let urlPath = url.urlsFromRootToSelf
        return try _getNode(urlPath.remainingUrls, currentNode: root)
    }

    private func _getNode(_ urlPath: [Absolute], currentNode: Node) throws -> Node? {
        guard let head = urlPath.first else {
            return currentNode
        }
        let remaining = Array(urlPath.dropFirst())
        let contents = currentNode.contents
        switch contents {
        case .file(_):
            throw Error.doesNotExist
        case .directory(let dir):
            guard let entry = dir.entries[head.lastPathComponent] else {
                return nil
            }
            return try _getNode(remaining, currentNode: entry)
        }
    }
}

// MARK: - Convenience
extension InMemoryFileSystem {
    public static func directory(_ entries: [String : Node] = [:]) -> Node {
        return .directory(entries)
    }
    public static func file(_ contents: String) -> Node {
        return .file(contents)
    }
}

// MARK: - Node
extension InMemoryFileSystem {
    public class Node {
        public static func directory(_ entries: [String : Node] = [:]) -> Node {
            return Node(NodeContents.directory(DirectoryContents(entries: entries)))
        }
        public static func file(_ contents: String) -> Node {
            return Node(NodeContents.file(contents))
        }
        private(set) var contents: NodeContents
        
        init(_ contents: NodeContents) {
            self.contents = contents
        }
        
        public subscript(name: String) -> Node? {
            get {
                return contents[name]
            }
            set {
                contents[name] = newValue
            }
        }
    }
}

extension InMemoryFileSystem.Node {
    final class DirectoryContents {
        var entries: [String: Node]
        init(entries: [String: Node] = [:]) {
            self.entries = entries
        }
        
        subscript(name: String) -> Node? {
            get {
                return entries[name]
            }
            set {
                entries[name] = newValue
            }
        }
    }
}

extension InMemoryFileSystem.Node {
    enum NodeContents {
        case file(String)
        case directory(DirectoryContents)
        
        // MARK: - Properties
        var fileContents: String? {
            if case let .file(contents) = self { return contents }
            return nil
        }
        var directoryContents: DirectoryContents? {
            if case let .directory(contents) = self { return contents }
            return nil
        }
        
        // MARK: - Only works for directories
        public subscript(name: String) -> Node? {
            get {
                return directoryContents?[name]
            }
            set {
                directoryContents?[name] = newValue
            }
        }
    }
}
