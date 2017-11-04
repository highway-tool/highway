import Foundation

extension _Highway {
    public class Raw<T: RawRepresentable> where T.RawValue == String {
        // MARK: - Types
        typealias HighwayBody = (Invocation) throws -> Any?
        
        // MARK: - Properties
        public var name: String
        public var usage: String?
        public var dependencies = [T]()
        public var result: Any?
        public var description: HighwayDescription {
            return HighwayDescription(name: name, usage: usage)
        }
        var body: HighwayBody?
        
        // MARK: - Init
        init(name: String, usage: String? = nil) {
            self.name = name
            self.usage = usage
        }
        
        // MARK: - Setting Bodies
        public static func ==> (lhs: Raw, rhs: @escaping () throws -> ()) {
            lhs.body = { _ in try rhs() }
        }
        public static func ==> (lhs: Raw, rhs: @escaping () throws -> (Any)) {
            lhs.body = { _ in try rhs() }
        }
        
        public static func ==> (lhs: Raw, rhs: @escaping (Invocation) throws -> (Any?)) {
            lhs.body = { try rhs($0) }
        }
        
        public static func ==> (lhs: Raw, rhs: @escaping (Invocation) throws -> ()) {
            lhs.body = {
                try rhs($0)
                return ()
            }
        }
        
        // MARK: - Set Dependencies
        public func depends(on highways: T...) -> Raw {
            dependencies = highways
            return self
        }
        
        // MARK: - Set Usage Descriptions
        public func usage(_ string: String) -> Raw {
            usage = string
            return self
        }
        
        // MARK: - Invoke the Highway
        func invoke(with invocation: Invocation) throws {
            result = try body?(invocation)
        }
    }
}
