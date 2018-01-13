import Foundation
import Task
import FileSystem
import Url
import Arguments
import enum Result.Result
import Terminal

/// Low-level Wrapper around xcodebuild. This is a starting point for additonal wrappers that do things like auto detection
/// of certain settings/options. However there are some things XCBuild already does which makes it a little bit more than
/// just a wrapper. It offers a nice struct around the export-plist, it interprets the results of executed commands
/// and finds generated files (ipas, ...). xcrun is also used throughout this class.
public final class XCBuild {
    // MARK: - Properties
    public let system: System
    public let fileSystem: FileSystem
    private let ui: UI
    
    // MARK: - Init
    public init(system: System, fileSystem: FileSystem, ui: UI) {
        self.system = system
        self.fileSystem = fileSystem
        self.ui = ui
        Terminal.shared.verbose = true
    }
    
    // MARK: - Incrementing the Build Number
    public struct BuildNumber {
        public var previous: String
        public var current: String
    }
    
    @discardableResult
    public func incrementBuildNumber(project: Absolute, scheme: String) throws -> BuildNumber {
        let plistUrl = try infoPlistUrl(project: project, scheme: scheme)
        let data = try fileSystem.data(at: plistUrl)
        let rawList = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        guard let _list = rawList as? [String:Any] else {
            throw "wrong format"
        }
        var list = _list
        guard let rawBuildNumber = list["CFBundleVersion"] as? String else {
            throw "CFBundleVersion not found or no string"
        }
        
        guard let buildNumber = Int(rawBuildNumber) else {
            throw "CFBundleVersion not found or no string"
        }
        
        let newNumber = String(buildNumber + 1)
        list["CFBundleVersion"] = newNumber
        let newData = try PropertyListSerialization.data(fromPropertyList: list, format: .xml, options: 0)
        try fileSystem.writeData(newData, to: plistUrl)
        return BuildNumber(previous: rawBuildNumber, current: newNumber)
    }
    
    private func infoPlistUrl(project: Absolute, scheme: String) throws -> Absolute {
        let settings = try buildSettings(project: project, scheme: scheme)
        
        // This can be absolute (/xxxx) or relative (../xxxx or just xxxx) - (god help if its nil)
        guard let rawPath = settings["INFOPLIST_FILE"] else {
            throw "Failed to determine location of Info.plist. No 'INFOPLIST_FILE' found in build settings."
        }
        
        return Absolute(path: rawPath, relativeTo: project.parent)
    }
    
    // MARK: - Getting Build Settings
    public func buildSettings(project: Absolute, scheme: String) throws -> [String : String] {
        let task = try _xcodebuild().dematerialize()
        task.arguments += _option("showBuildSettings")
        task.arguments += _option("scheme", value: scheme)
        task.arguments += _option("project", value: project.path)
        task.enableReadableOutputDataCapturing()

        try system.execute(task).assertSuccess()
        guard let output = task.trimmedOutput else {
            throw "Failed to get build settings. xcodebuild returned without errors but no output."
        }
        
        typealias Pair = (String, String)
        // Build settings for action build and target highwayiostest:
        //    ACTION = build
        let lines = output.trimmedLines
        let pairs: [Pair] = lines.flatMap { line in
            let components = line.components(separatedBy: " = ")
            guard components.count == 2 else {
                return nil
            }
            let key = components[0]
            let value = components[1]
            return (key: key, value: value)
        }
        
        let env:[String:String] = Dictionary(pairs, uniquingKeysWith: { (_, new) in new  })
        return env
    }

    // MARK: - Archiving
    @discardableResult
    public func archive(using options: ArchiveOptions) throws -> Archive {
        var options = options
        if options.destination == nil {
            options.destination = Destination.generic(platform: ArchivePlatform.iOS.rawValue)
        }
        let task = try _archiveTask(using: options).dematerialize()
        try system.execute(task).assertSuccess()
        guard let archivePath = options.archivePath else {
            throw "Archive failed. No archivePath set."
        }
        return try Archive(url: archivePath, fileSystem: fileSystem)
    }
    
    private func _archiveTask(using options: ArchiveOptions) throws -> Result<Task, TaskCreationError> {
        let result = _xcodebuild()
        let task = try result.dematerialize()
        task.arguments += options.arguments
        switch options.logDestination {
            
        case .standardStream: ()
            // do nothing
        case .file(let logFile):
            let logHandle = try FileHandle(forWritingTo: logFile.url)
            task.output = .init(logHandle)
        }
        return result
    }
    
    // MARK: Exporting
    @discardableResult
    public func export(using options: ExportArchiveOptions) throws -> Export {
        let task = try _exportTask(using: options).dematerialize()
        try system.execute(task).assertSuccess()
        guard let exportPath = options.exportPath else {
            throw "Export failed. No archivePath set."
        }
        return try Export(url: exportPath, fileSystem: fileSystem)
    }
    
    private func _exportTask(using options: ExportArchiveOptions) -> Result<Task, TaskCreationError> {
        let result = _xcodebuild()
        result.value?.arguments += options.arguments
        return result
    }
    
    // MARK: Build & Test
    @available(*, deprecated)
    public func buildAndTest(using options: BuildOptions) throws {
        try build(using: options, executeTests: true)
    }
    
    public func build(using options: BuildOptions, executeTests: Bool) throws {
        var options = options
        if options.destination == nil {
            options.destination = try _buildDestination(using: options, executeTests: executeTests)
        }
        let xcbuild = try _buildTask(using: options, executeTests: executeTests).dematerialize()
        if let xcpretty = system.task(named: "xcpretty").value {
            xcbuild.output = .pipe()
            xcbuild.environment["NSUnbufferedIO"] = "YES" // otherwise xcpretty might not get everything
            xcpretty.input = xcbuild.output
            try system.launch(xcbuild, wait: false).assertSuccess()
            try system.execute(xcpretty).assertSuccess()
        } else {
            try system.execute(xcbuild).assertSuccess()
        }
    }
    
    @discardableResult
    public func _buildDestination(using options: BuildOptions, executeTests: Bool) throws -> Destination? {
        ui.message("Trying to detect destination…")
        var options = options
        options.destinationTimeout = 1
        options.destination = Destination.named("NoSuchName")
        let xcbuild = try _buildTask(using: options, executeTests: executeTests).dematerialize()
        xcbuild.enableErrorOutputCapturing()
        _ = system.execute(xcbuild)
        guard let output = xcbuild.trimmedErrorOutput else {
            ui.error("Unable to detect destionation. Got no output from xcodebuild.")
            return nil
        }
        guard let destination = Destination.destinations(xcbuildOutput: output).first else {
            ui.error("Failed to detect destination. xcodebuild used to detect the destination:\n\n\(output)")
            return nil
        }
        ui.verbose("Detected destination: \(destination.asString)")
        return destination
    }
    
    private func _buildTask(using options: BuildOptions, executeTests: Bool) -> Result<Task, TaskCreationError> {
        let result = _xcodebuild()
        result.value?.arguments += options.arguments(executeTests: executeTests)
        return result
    }
    
    // MARK: Helper
    private func _xcodebuild() -> Result<Task, TaskCreationError> {
        let result = system.task(named: "xcrun")
        result.value?.arguments = ["xcodebuild"]
        return result
    }
}

fileprivate struct XCodeBuildOption {
    fileprivate init(name: String, value: String?, ignoresOptionWithoutValue: Bool = false) {
        self.name = name
        self.value = value
        self.ignoresOptionWithoutValue = ignoresOptionWithoutValue
    }
    fileprivate let name: String
    fileprivate var value: String?
    fileprivate var ignoresOptionWithoutValue: Bool
}

extension XCodeBuildOption: ArgumentsConvertible {
    func arguments() -> Arguments? {
        if ignoresOptionWithoutValue && value == nil {
            return nil
        }
        return Arguments(["-" + name, value ?? ""])
    }
}

private func _option(_ name: String, value: String? = nil) -> XCodeBuildOption {
    return XCodeBuildOption(name: name, value: value)
}

private func _intOption(_ name: String, value: Int?) -> XCodeBuildOption {
    let stringValue: String?
    if let value = value {
        stringValue = String(value)
    } else {
        stringValue = nil
    }
    return XCodeBuildOption(name: name, value: stringValue, ignoresOptionWithoutValue: true)
}

fileprivate extension ArchiveOptions {
    var arguments: Arguments {
        var args = Arguments.empty
        args += _option("scheme", value: scheme)
        args += _option("project", value: project?.path)
        args += _option("destination", value: destination.map { "\($0.asString)" })
        args += _option("archivePath", value: archivePath?.path)
        args.append("archive")
        return args
    }
}

fileprivate extension ExportArchiveOptions {
    var arguments: Arguments {
        var args = Arguments("-exportArchive")
        args += _option("exportOptionsPlist", value: exportOptionsPlist?.url.path)
        args += _option("archivePath", value: archivePath?.path)
        args += _option("exportPath", value: exportPath?.path)
        return args
    }
}

fileprivate extension BuildOptions {
    func arguments(executeTests: Bool) -> Arguments {
        var args = Arguments.empty
        args += _option("scheme", value: scheme)
        args += _option("project", value: project?.path)
        args += _option("destination", value: destination.map { "\($0.asString)" })
        args += _intOption("destination-timeout", value: destinationTimeout)
        args.append("build")
        if executeTests {
            args.append("test")
        }
        return args
    }
}

