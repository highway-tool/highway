import Foundation
import Arguments
import Terminal

public final class SystemExecutor: TaskExecutor {
    public var ui: UI
    
    // MARK: - Init
    public init(ui: UI) {
        self.ui = ui
    }
   
    // MARK: - Working with the Executor
    public func launch(task: Task, wait: Bool) {
        let process = task.toProcess
        ui.verbose(task.description)
        task.state = .executing
        process.launch()
        if wait {
            process.waitUntilExit()
        }
        if task.successfullyFinished == false {
            ui.error(task.state.description)
        } else {
            ui.verbose(task.state.description)
        }
    }
}

private extension Process {
    func takeIOFrom(_ task: Task) {
        standardInput = task.input.asProcessChannel
        standardOutput = task.output.asProcessChannel
        standardError = task.error.asProcessChannel
    }
}

// internal because it is tested
internal extension Task {
    internal var toProcess: Process {
        let result = Process()
        result.arguments = arguments.asProcessArguments
        result.launchPath = executableUrl.path
        if let currentDirectoryPath = currentDirectoryUrl?.path {
            result.currentDirectoryPath = currentDirectoryPath
        }
        var _environment: [String:String] = ProcessInfo.processInfo.environment
        self.environment.forEach {
            _environment[$0.key] = $0.value
        }
        result.environment = _environment
        result.terminationHandler = { terminatedProcess in
            self.state = .terminated(Termination(describing: terminatedProcess))
        }
        result.takeIOFrom(self)
        return result
    }
}
