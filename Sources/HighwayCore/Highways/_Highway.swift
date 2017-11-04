import Foundation
import Arguments

infix operator ==>

open class _Highway<T: RawRepresentable> where T.RawValue == String {
    // MARK: - Types
    public typealias ErrorHandler = (Error) -> ()
    public typealias EmptyHandler = () throws -> ()
    public typealias UnrecognizedCommandHandler = (_ arguments: Arguments) throws -> ()

    // MARK: - Init
    public init(_ type: T.Type) {
        setupHighways()
    }
    
    // MARK: - Properties
    private var _highways = OrderedDictionary<String, Raw<T>>()
    public var onError: ErrorHandler?
    public var onEmptyCommand: EmptyHandler? = { }
    public var onUnrecognizedCommand: UnrecognizedCommandHandler?
    public var verbose = false
    public var descriptions: [HighwayDescription] {
        return _highways.values.map { $0.description }
    }

    // MARK: - Subclasses
    open func setupHighways() { }
    
    // MARK: - Adding Highway
    public subscript(type: T) -> Raw<T> {
        return _highways[type.name, default: Raw(name: type.name)]
    }

    public func highway(_ highway: T, _ usage: String, command: String? = nil) -> Raw<T> {
        let command = command ?? highway.name
        let raw = Raw<T>(name: command, usage: usage)
        _highways.append(raw, forKey: command)
        return raw
    }

    public func highway(_ highway: T) -> Raw<T> {
        let command = highway.name
        let raw = Raw<T>(name: command)
        _highways.append(raw, forKey: command)
        return raw
    }
    
    // MARK: Getting Results
    public func result<ObjectType>(for highway: T) throws -> ObjectType {
        guard let value = _highways[highway.name]?.result as? ObjectType else {
            throw "No result or type mismatch for \(ObjectType.self)"
        }
        return value
    }
    
    // MARK: Executing
    private func _handle(highway: Raw<T>, with arguments: Arguments) throws {
        let dependencies: [Raw<T>] = try highway.dependencies.map { dependency in
            guard let result = _highways[dependency.name] else {
                throw "\(highway.name) depends on \(dependency) but no such highway is registered."
            }
            return result
        }
        try dependencies.forEach {
            try self._handle(highway: $0, with: arguments)
        }
        do {
            let invocation = Invocation(highway: highway.name, arguments: arguments)
            try highway.invoke(with: invocation) // Execute and sets the result
        } catch {
            _reportError(error)
            throw error
        }
    }
    
    public func invocation(`for` highway: T) -> Invocation {
        return Invocation(highway: highway.name, verbose: verbose)
    }
    
    /// Calls the error handler with the given error.
    /// If no error handler is set the error is logged.
    ///
    /// - Parameter error: An error to be passed to the error handler
    private func _reportError(_ error: Error) {
        guard let errorHandler = onError else {
            print("[ERROR] \(error.localizedDescription)")
            return
        }
        errorHandler(error)
    }
    
    private func _handleEmptyCommandOrReportError() {
        guard let emptyHandler = onEmptyCommand else {
            _reportError("No empty handler set.")
            return
        }
        do {
            try emptyHandler()
        } catch {
            _reportError(error)
        }
    }
    
    private func _handleUnrecognizedCommandOrReportError(arguments: Arguments) {
        guard let unrecognizedHandler = onUnrecognizedCommand else {
            _reportError("Unrecognized command detected. No highway matching \(arguments) found and no unrecognized command handler set.")
            return
        }
        do {
            try unrecognizedHandler(arguments)
        } catch {
            _reportError(error)
        }
    }
    
    open func didFinishLaunching(with invocation: Invocation) { }
    
    public func go(_ invocationProvider: InvocationProvider = CommandLineInvocationProvider()) {
        let invocation = invocationProvider.invocation()
        verbose = invocation.verbose
        didFinishLaunching(with: invocation)

        // Empty?
        if invocation.representsEmptyInvocation {
            _handleEmptyCommandOrReportError()
            return
        }
        
        // Remaining highways
        let highwayName = invocation.highway
        guard let highway = _highways[highwayName] else {
            _handleUnrecognizedCommandOrReportError(arguments: invocation.arguments)
            return
        }

        do {
            try _handle(highway: highway, with: invocation.arguments)
        } catch {
            // Do not rethrow or report the error because _handle did that already
        }
    }
}

extension RawRepresentable where Self.RawValue == String {
    var name: String {
        return rawValue
    }
}
