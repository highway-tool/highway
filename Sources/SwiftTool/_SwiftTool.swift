import Foundation
import Url
import Task
import Arguments
import Terminal

public class _SwiftTool {
    // MARK: - Properties
    public let system: System
    public let ui: UI
    
    // MARK: - Init
    public init(system: System, ui: UI) {
        self.system = system
        self.ui = ui
    }
}

extension _SwiftTool: SwiftTool {
    public func test(projectAt url: Absolute) throws {
        let task = try system.xcrun("swift", arguments: ["test"])
        task.currentDirectoryUrl = url
        try system.execute(task).assertSuccess()
    }
    
    public func build(projectAt url: Absolute, options: SwiftOptions) throws -> Artifact {
        let buildTask = try system.swift(projectAt: url, options: options, additionalArguments: [])
        buildTask.enableReadableOutputDataCapturing()
        buildTask.enableErrorOutputCapturing()
        let buildResult = system.execute(buildTask)
        let log = buildTask.trimmedOutput ?? "<none>"
        if buildResult.error != nil {
            let errorOut = buildTask.trimmedErrorOutput ?? "<none>"
            let message = "Failed to build. non-0 exit code. Build log: \(log)\n\nError Log: \n\n\(errorOut)"
            ui.error(message)
            throw message
        }

        try buildResult.assertSuccess()
        
        var pathOptions = options
        pathOptions.verbose = false
        let pathTask = try system.swift(projectAt: url, options: pathOptions, additionalArguments: ["--show-bin-path"])
        pathTask.enableReadableOutputDataCapturing()
        try system.execute(pathTask).assertSuccess()
        
        guard let rawPath = pathTask.trimmedOutput, rawPath.isEmpty == false else {
            let message = "Build failed because bin path does not seem to be valid."
            ui.error(message)
            throw message
        }
        
        return Artifact(binUrl: Absolute(rawPath), buildOutput: log)
    }
    
    public func generateProject(with options: XcodeprojOptions) throws {
        let arguments = options.arguments
        let task = try _packageProcess(arguments: arguments, currentDirectoryUrl: options.swiftProject)
        try system.execute(task).assertSuccess()
    }
    
    public func update(projectAt url: Absolute) throws {
        let task = try _packageProcess(arguments: ["update"], currentDirectoryUrl: url)
        try system.execute(task).assertSuccess()
    }
    
    private func _packageProcess(arguments: Arguments, currentDirectoryUrl: Absolute) throws -> Task {
        let task = try system.xcrun("swift", arguments: ["package"] + arguments)
        task.currentDirectoryUrl = currentDirectoryUrl
        task.enableReadableOutputDataCapturing()
        return task
    }
}

extension System {
    fileprivate func swift(projectAt projectUrl: Absolute, options: SwiftOptions, additionalArguments: Arguments) throws -> Task {
        let arguments = options._processArguments + additionalArguments
        let task = try xcrun("swift", arguments: arguments)
        task.currentDirectoryUrl = projectUrl
        return task
    }
}


