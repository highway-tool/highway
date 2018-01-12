import HighwayCore
import Foundation
import FileSystem
import Terminal
import HighwayCore
import Url
import Task
import Arguments
import SwiftTool

/// This class makes it easy to work with the highway project (aka _highway).
/// Specifically, this class can:
///     - Retrieve all highways offered by _highway.
///     - Build the highway project. (+ fallback)
///     - Execute the highway project executable.
public class HighwayProjectTool {
    // MARK: - Properties
    public let system: System
    public let compiler: SwiftTool
    public let bundle: HighwayBundle
    public var fileSystem: FileSystem
    public let verbose: Bool
    public let ui: UI
    
    // MARK: - Init
    public init(
        compiler: SwiftTool,
        bundle: HighwayBundle,
        system: System,
        fileSystem: FileSystem,
        verbose: Bool,
        ui: UI) {
        self.compiler = compiler
        self.system = system
        self.bundle = bundle
        self.fileSystem = fileSystem
        self.verbose = verbose
        self.ui = ui
    }
    
    // MARK: - Working with the Tool
    public func projectDescription() throws -> ProjectDescription {
        try build(thenExecuteWith: [])
        let url = bundle.projectDescriptionUrl
        ui.verbose("Reading project description: \(url)")
        let data = try fileSystem.data(at: url)
        let result = try JSONDecoder().decode(ProjectDescription.self, from: data)
        ui.verbose("Project description: \(try result.jsonString())")
        return result
    }
    
    public func availableHighways() -> [HighwayDescription] {
        return (try? projectDescription().highways) ?? []
    }

    public func update() throws {
        try compiler.update(projectAt: bundle.url)
    }
    
    public func build() throws -> BuildResult {
        let artifact = try compiler.compile(bundle: bundle)
        let url = bundle.executableUrl(swiftBinUrl: artifact.binUrl)
        return BuildResult(executableUrl: url, artifact: artifact)
    }
    
    @discardableResult
    public func build(thenExecuteWith arguments: Arguments) throws -> BuildThenExecuteResult {
        let buildResult = try build()
        
        let executableUrl = buildResult.executableUrl
        
        try fileSystem.assertItem(at: executableUrl, is: .file)
        var arguments = arguments
        if verbose {
            arguments = Arguments(["--verbose"]) + arguments
        }
        let _highway = Task(executableUrl: executableUrl, arguments: arguments, currentDirectoryUrl: bundle.url.parent)
        _highway.output = .standardOutput()
        ui.verbose("Launching: \(_highway)")

        try system.execute(_highway).assertSuccess()
        
        let output = _highway.capturedOutputData ?? Data()
        return BuildThenExecuteResult(buildResult: buildResult, outputData: output)
    }
}

public extension HighwayProjectTool {
    public struct BuildResult {
        // MARK: - Init
        public init(executableUrl: Absolute, artifact: Artifact) {
            self.executableUrl = executableUrl
            self.artifact = artifact
        }
        // MARK: - Properties
        public let executableUrl: Absolute
        public let artifact: Artifact
    }
}

public extension HighwayProjectTool {
    public struct BuildThenExecuteResult {
        // MARK: - Init
        public init(buildResult: BuildResult, outputData: Data) {
            self.buildResult = buildResult
            self.outputData = outputData
        }
        // MARK: - Properties
        public let buildResult: BuildResult
        public let outputData: Data
    }
}


