import Foundation

public enum Result<Value> {
    case success(Value)
    case failure(Error)
    
    // MARK: - Init
    public init(_ value: Value) {
        self = .success(value)
    }
    public init(_ error: Error) {
        self = .failure(error)
    }
    // MARK: - Working with the Result
    
    public func map<U>(_ transform: (Value) -> U) -> Result<U> {
        switch self {
        case .success(let value):
            return Result<U>(transform(value))
        case .failure(let error):
            return Result<U>(error)
        }
    }
    
    public func map<U>(_ transform: (Value) -> Result<U>) -> Result<U> {
        switch self {
        case .success(let value):
            let innerResult = transform(value)
            switch innerResult {
            case .success(let innerValue):
                return Result<U>(innerValue)
            case .failure(let innerError):
                return Result<U>(innerError)
            }
        case .failure(let error):
            return Result<U>(error)
        }
    }
    
    public func dematerialize() throws -> Value {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    public func assertSuccess() throws {
        switch self {
        case .failure(let error): throw error
        default: break
        }
    }
}
