import Foundation
import FileSystem
import Url
import POSIX

/**
.
└── your app/
    ├── _highway/
    │   ├── .gitignore
    │   ├── .build/
    │   ├── .project_description.json
    │   ├── Package.resolved
    │   ├── Package.swift
    │   ├── config.xcconfig
    │   └── main.swift
    ├── _highway.xcodeproj/
    └── your app.xcodeproj/
 */

public final class HighwayBundle {
    // MARK: - Init
    public init(url: Absolute, fileSystem: FileSystem, configuration: Configuration = .standard) throws {
        try fileSystem.assertItem(at: url, is: .directory)

        self.url = url
        self.fileSystem = fileSystem
        self.configuration = configuration
    }

    public convenience init(fileSystem: FileSystem, parentUrl: Absolute = abscwd(), configuration: Configuration = .standard) throws {
        let url = parentUrl.appending(configuration.directoryName)
        try self.init(url: url, fileSystem: fileSystem, configuration: configuration)
    }

    // MARK: - Properties
    public let url: Absolute
    public let fileSystem: FileSystem
    public let configuration: Configuration
    public var xcodeprojectParent: Absolute {
        return url.parent
    }
    public var xcodeprojectUrl: Absolute {
        return url.parent.appending(configuration.xcodeprojectName)
    }
    
    // MARK: - Writing
    public func write(xcconfigData data: Data) throws {
        try fileSystem.writeData(data, to: xcconfigFileUrl)
    }
    
    public func write(gitignore data: Data) throws {
        try fileSystem.writeData(data, to: url.appending(configuration.gitignoreName))
    }
    
    public func write(mainSwiftData data: Data) throws {
        try fileSystem.writeData(data, to: mainSwiftFileUrl)
    }
    
    public func write(packageDescription data: Data) throws {
        try fileSystem.writeData(data, to: packageFileUrl)
    }
    
    public func write(projectDescription: ProjectDescription) throws {
        let data = try JSONEncoder().encode(projectDescription)
        try fileSystem.writeData(data, to: projectDescriptionUrl)
    }
    
    // MARK: - Deleting
    public func deletePinsFileIfPresent() throws -> Absolute? {
        return try fileSystem.delete(file: pinsFileUrl)
    }
    
    public func deleteBuildDirectoryIfPresent() throws -> Absolute? {
        return try fileSystem.delete(directory: buildDirectory)
    }
    
    public func deleteProjectDescriptionIfPresent() throws -> Absolute? {
        return try fileSystem.delete(file: projectDescriptionUrl)
    }
    
    // MARK: - Working with the Bundle
    public var gitignoreFileUrl: Absolute {
        return url.appending(configuration.gitignoreName)
    }

    public var xcconfigFileUrl: Absolute {
        return url.appending(configuration.xcconfigName)
    }
    
    public var projectDescriptionUrl: Absolute {
        return url.appending(configuration.projectDescriptionName)
    }

    public var mainSwiftFileUrl: Absolute {
        return url.appending(configuration.mainSwiftFileName)
    }

    public var packageFileUrl: Absolute {
        return url.appending(configuration.packageSwiftFileName)
    }

    private var pinsFileUrl: Absolute {
        return url.appending(configuration.pinsFileName)
    }

    public var buildDirectory: Absolute {
        return url.appending(configuration.buildDirectoryName)
    }
    
    // MARK: - Cleaning
    public struct CleanResult {
        public let deletedFiles: [Absolute]
    }
    
    /// Removes build artifacts and calculateable information from the
    /// highway bundle = the folder that contains your custom "highfile".
    public func clean() throws -> CleanResult {
        return CleanResult(deletedFiles:
            [
                try deletePinsFileIfPresent(),
                try deleteBuildDirectoryIfPresent(),
                try deleteProjectDescriptionIfPresent()
            ].flatMap { $0 } )
    }

    public func executableUrl(swiftBinUrl: Absolute) -> Absolute {
        return swiftBinUrl.appending(configuration.targetName)
    }
}

extension HighwayBundle {
    public struct Configuration {
        // MARK: - Getting the default Configuration
        public static let standard: Configuration = {
            var config = Configuration()
            config.branch = env("HIGHWAY_BUNDLE_BRANCH", defaultValue: "master")
            return config
        }()
        
        // MARK: - Properties
        public var mainSwiftFileName = "main.swift"
        public var packageSwiftFileName = "Package.swift"
        public var xcodeprojectName = "_highway.xcodeproj"
        public var packageName = "_highway"
        public var targetName = "_highway"
        public var directoryName = "_highway"
        public var buildDirectoryName = ".build" // there is a bug in PM: generating the xcode project causes .build to be used every time...
        public var pinsFileName = "Package.resolved"
        // MARK: - Properties / Convenience
        public var xcconfigName = "config.xcconfig"
        public var gitignoreName = ".gitignore"
        public var projectDescriptionName = ".project_description.json"
        // MARK: - Private Stuff
        public var branch = "master"
    }
}
