import Url
import Arguments
import Task
import FileSystem
import enum Result.Result
import Errors

public class Altool {
    // MARK: - Properties
    public let system: System
    public let fileSystem: FileSystem
    
    // MARK: - Executable Provider
    /// Returns an ExecutableProvider that is capable to find altool if it does exist.
    public class func executableProvider(developerDirectory: Absolute, fileSystem: FileSystem) -> ExecutableProvider {
        return AltoolProvider(developerDirectory: developerDirectory, fileSystem: fileSystem)
    }
    
    // MARK: - Init
    public init(system: System, fileSystem: FileSystem) {
        self.system = system
        self.fileSystem = fileSystem
    }
    
    // MARK: - Working with the Tool
    public enum Error: Swift.Error {
        case other(ErrorMessage)
        case executionError(ExecutionError)
    }
    
    public func execute(with options: Options) -> Result<Void, Error> {
        let taskResult = _task(with: options)
        switch taskResult {
        case .success(let task):
            switch system.execute(task) {
            case .success:
                return .success(())
            case .failure(let executionError):
                return .failure(.executionError(executionError))
            }
        case .failure(let errorMessage):
            return .failure(.other(errorMessage))
        }
    }
    
    // MARK: - Helper
    private func _task(with options: Options) -> Result<Task, ErrorMessage> {
        let result = system.task(named: "altool")
        switch result {
        case .success(let task):
            task.arguments += options.arguments
            return Result.success(task)
        case .failure(let error):
            return Result.failure(error.localizedDescription)
        }
    }
}

private class AltoolProvider {
    // MARK: - Properties
    /// Something like '/Applications/Xcode.app/Contents/Developer'
    private let developerDirectory: Absolute
    private let fileSystem: FileSystem
    
    // MARK: - Init
    init(developerDirectory: Absolute, fileSystem: FileSystem) {
        self.developerDirectory = developerDirectory
        self.fileSystem = fileSystem
    }
    
    // MARK: - Working with the Provider
    func executableUrl() -> Result<Absolute, ErrorMessage> {
        let url = developerDirectory.parent.appending("Applications/Application Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Versions/A/Support/altool")
        guard fileSystem.file(at: url).isExistingFile else {
            return .failure("altool not found in '\(url)'.")
        }
        return .success(url)
    }
}

extension AltoolProvider: ExecutableProvider {
    func urlForExecuable(_ executableName: String) -> Absolute? {
        guard executableName == "altool" else { return nil }
        return executableUrl().value
    }
}
