import Foundation

public protocol ArgumentsConvertible {
    func arguments() -> Arguments?
}

public protocol Argument {
    var processArgumentValue: String { get }
    var loggableDescription: String { get }
}

extension Array where Element == Argument {
    public var processArguments: [String] {
        return map { $0.processArgumentValue }
    }
}

extension String: Argument {
    public var processArgumentValue: String {
        return self
    }
    
    public var loggableDescription: String {
        return self
    }
}

extension Argument {
    func isEqual(to other: Argument) -> Bool {
        return false
    }
}

public extension Array where Element == Argument {
    public var processArgumentValues: [String] {
        return map { $0.processArgumentValue }
    }
    public var loggableValues: [String] {
        return map { $0.loggableDescription }
    }
}

public struct SecureString {
    public init(_ value: String) {
        self.value = value
    }
    public let value: String
}

extension SecureString: Argument {
    public var processArgumentValue: String {
        return value
    }
    
    public var loggableDescription: String {
        return "<•••••••••••••••••••••••><####>"
    }
}

public struct Arguments {
    // MARK: - Convenience
    public static let empty = Arguments()
    
    // MARK: - Init
    public init(all: [String] = []) {
        append(contentsOf: all)
    }
    
    public init(_ all: [String] = []) {
        append(contentsOf: all)
    }
    
    public init(arguments: [Argument]) {
        self.all = arguments
    }
    
    public init(argumentsArray: [Arguments]) {
        let allArray: [[Argument]] = argumentsArray.map { $0.all }
        self.all = Array(allArray.joined())
    }
    
    public init(_ arg: String) {
        self.init([arg])
    }
    
    // MARK: - Properties
    public var count: Int { return all.count }
    public var all: [Argument] = [] {
        didSet {
            self.all = all.filter { $0.processArgumentValue.isEmpty == false }
        }
    }
    
    public var asProcessArguments: [String] {
        return all.processArgumentValues
    }
    
    public var loggableValues: [String] {
        return all.loggableValues
    }
    
    public var remaining: Arguments {
        return Arguments(arguments: Array(all.dropFirst()))
    }
    
    // MARK: - Finding
    public func contains(_ argument: String) -> Bool {
        return all.contains { arg in
            return arg.processArgumentValue == argument
        }
    }
    // MARK: - Appending
    public mutating func append(_ arg: String) {
        append(contentsOf: [arg])
    }
    
    public mutating func append(contentsOf args: [String]) {
        all += (args as [Argument])
    }
    
    public mutating func append(_ arguments: Arguments) {
        all += arguments.all
    }
    
    public mutating func append(_ option: ArgumentsConvertible) {
        guard let args = option.arguments() else { return }
        append(args)
    }
    static public func +=(lhs: inout Arguments, rhs: ArgumentsConvertible) {
        var result = lhs
        result.append(rhs)
        lhs = result
    }
    static public func +=(lhs: inout Arguments, rhs: Arguments) {
        var result = lhs
        result.append(rhs)
        lhs = result
    }
    static public func +=(lhs: inout Arguments, rhs: String) {
        var result = lhs
        result.append(rhs)
        lhs = result
    }
    static public func +=(lhs: inout Arguments, rhs: [String]) {
        var result = lhs
        result.append(contentsOf: rhs)
        lhs = result
    }
    static public func +(lhs:  Arguments, rhs: Arguments) -> Arguments {
        var result = lhs
        result += rhs
        return result
    }
    static public func +(lhs:  Arguments, rhs: ArgumentsConvertible) -> Arguments {
        var result = lhs
        result += rhs
        return result
    }
    static public func +(lhs:  Arguments, rhs: String) -> Arguments {
        var result = lhs
        result += rhs
        return result
    }
}

extension Arguments: Equatable {
    public static func ==(l: Arguments, r: Arguments) -> Bool {
        guard l.count == r.count else {
            return false
        }
        let both = zip(l.all, r.all)
        return !(both.contains { (arg) in arg.0.isEqual(to: arg.1) })
    }
}
extension Arguments: CustomStringConvertible {
    public var description: String {
        return all.map { $0.loggableDescription }.joined(separator: " ")
    }
}

extension Arguments: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: String...) {
        self.init(elements)
    }
}
