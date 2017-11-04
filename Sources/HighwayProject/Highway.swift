import Foundation
import FileSystem
import XCBuild
import Task
import HighwayCore
import Terminal
import Deliver
import POSIX
import Git
import SwiftTool
import HWKit
import Keychain
import Url

private func _developerDirectory() -> Absolute {
    let system = LocalSystem.local()
    let defaultDir: Absolute = "/Applications/Xcode.app/Contents/Developer"
    do {
        let xcrun = try system.task(named: "xcrun").dematerialize()
        xcrun.arguments.append(contentsOf: ["xcode-select", "-p"])
        xcrun.enableReadableOutputDataCapturing()
        try system.execute(xcrun).assertSuccess()
        guard let developerDirectory = xcrun.trimmedOutput else {
            return defaultDir
        }
        return Absolute(developerDirectory)
    } catch {
        return defaultDir
    }
}

open class Highway<T: RawRepresentable>: _Highway<T> where T.RawValue == String {
    // MARK: - Init
    public override init(_ type: T.Type) {
        super.init(type)
        onError = { error in
            self.ui.error(error.localizedDescription)
        }
    }
    
    // MARK: - Properties
    public let fileSystem: FileSystem = LocalFileSystem()
    public let cwd = abscwd()
    
    public lazy var system: System = {
        let altoolProvider = Altool.executableProvider(developerDirectory: _developerDirectory(), fileSystem: fileSystem)
        return LocalSystem.local(additionalProviders: [altoolProvider])
    }()
    
    public lazy var ui: UI = {
        let invocation = CommandLineInvocationProvider().invocation()
        Terminal.shared.verbose = invocation.verbose
        return Terminal.shared
    }()
    
    public lazy var git: GitTool = {
        return _GitTool(system: system)
    }()
    
    public lazy var keychain: Keychain = {
        return Keychain(system: system)
    }()

    public lazy var deliver: _Deliver = {
        return Deliver.Local(altool: Altool(system: system, fileSystem: fileSystem))
    }()
    
    public lazy var xcbuild: XCBuild = {
        return XCBuild(system: system, fileSystem: fileSystem, ui: ui)
    }()
    
    public lazy var swift: SwiftTool = {
        return _SwiftTool(system: system, ui: ui)
    }()
    
    // MARK: - _Highway
    open override func didFinishLaunching(with invocation: Invocation) {
        ui.verbosePrint(Diagnostics(version: nil, system: system))
        
        super.didFinishLaunching(with: invocation)
        do {
            let text = try descriptions.jsonString()
            let config = HighwayBundle.Configuration.standard
            let url = cwd.appending(config.directoryName).appending(config.projectDescriptionName)
            try fileSystem.writeString(text, to: url)
        } catch {
            ui.error(error.localizedDescription)
        }
    }
    
    // MARK: - Convenience
    public func hw_build() throws {
        try xcbuild.build(using: xcsettings.build, executeTests: false)
    }
    
    public func hw_test() throws {
        try xcbuild.build(using: xcsettings.build, executeTests: true)
    }
    
    public func hw_deliver(platform: Deliver.Platform = .iOS) throws {
        // Validate xcsettings
        let user = try xcsettings.credentials.user.failIfNil("Failed to deliver product: User not set. You can set a user by setting xcsettings.credentials.user.")
        let password = try xcsettings.credentials.password.failIfNil("Failed to deliver product: Password not set. You can set a password by setting xcsettings.credentials.password.")
        
        let export = try hw_export()
        let options = Deliver.Options(ipaUrl: export.ipaUrl, username: user, password: .plain(password), platform: platform)
        try deliver.now(with: options)
    }
    
    @discardableResult
    public func hw_archive() throws -> Archive {
        let options = xcsettings.archive
        
        // Validate
        if let archivePath = options.archivePath,
           let archiveName = xcsettings.archiveName {
            ui.warn("[hw_archive] You cannot set both (xcsettings.archiveName ('\(archiveName)') and xcsettings.archive.archivePath ('\(archivePath)')). Falling back to xcsettings.archiveName.")
        }
        
        if options.archivePath == nil {
            xcsettings.archive.archivePath = try fileSystem.uniqueTemporaryDirectoryUrl().appending((xcsettings.archiveName ?? "archive") + ".xcarchive")
        }
        
        return try xcbuild.archive(using: xcsettings.archive)
    }
    
    @discardableResult
    public func hw_export() throws -> Export {
        let archive = try hw_archive()
        var options = xcsettings.exportArchive
        try options.exportPath <-> fileSystem.uniqueTemporaryDirectoryUrl()
        
        if options.exportPath == nil {
            options.exportPath = try fileSystem.uniqueTemporaryDirectoryUrl()
        }
        options.archivePath <-> archive.url
        
        return try xcbuild.export(using: options)
    }
    
    public func hw_incrementBuildNumber() throws {
        // Validate xcsettings
        let project = try xcsettings.projectUrl.failIfNil("Failed to increment build number: project url not set.")
        let scheme = try xcsettings.scheme.failIfNil("Failed to increment build number: scheme url not set.")

        // Do it
        try xcbuild.incrementBuildNumber(project: project, scheme: scheme)
    }
    
    public let xcsettings = XCSettings()
}

infix operator <-> : AssignIfNilPrecedence
precedencegroup AssignIfNilPrecedence {
    associativity: left
}

@discardableResult
func <-><T> (value: inout Optional<T>, fallback: @autoclosure () throws -> T?) rethrows -> T? {
    if let value = value {
        return value
    }
    let fallback = try fallback()
    value = fallback
    return fallback
}
extension Optional {
    func failIfNil(_ error: Swift.Error) throws -> Wrapped {
        guard let value = self else {
            throw error
        }
        return value
    }
}

public struct Credentials {
    public var user: String?
    public var password: String?
}

public class XCSettings {
    public var credentials = Credentials()
    public var projectUrl: Absolute?
    public var scheme: String?
    public var archiveName: String? = nil
    public var archive: ArchiveOptions {
        get {
            var _archive = self._archive
            _archive.project = _archive.project ?? projectUrl
            _archive.scheme = _archive.scheme ?? scheme
            return _archive
        }
        set { _archive = newValue }
    }
    public var build: BuildOptions {
        get {
            var _build = self._build
            _build.project = _build.project ?? projectUrl
            _build.scheme = _build.scheme ?? scheme
            return _build
        }
        set { _build = newValue }
    }
//    public var export = ExportOptions()
    public var exportArchive = ExportArchiveOptions()
    
    private var _archive = ArchiveOptions()
    private var _build = BuildOptions()

}
