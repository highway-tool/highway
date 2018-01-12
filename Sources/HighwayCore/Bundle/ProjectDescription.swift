import Foundation

public struct ProjectDescription: Codable {
    // MARK: - Properties
    public let highways: [HighwayDescription]
    public let credentials: Credentials?
    
    // MARK: - Init
    public init(highways: [HighwayDescription], credentials: Credentials?) {
        self.highways = highways
        self.credentials = credentials
    }
    
    // MARK: - Convenience
    public func jsonString() throws -> String {
        let coder = JSONEncoder()
        let data = try coder.encode(self)
        guard let string = String(data: data, encoding: .utf8) else {
            throw "Failed to convert data to String."
        }
        return string
    }
}

extension ProjectDescription {
    public struct Credentials: Codable {
        // MARK: - Properties
        public let user: String
        
        // MARK: - Init
        public init(user: String) {
            self.user = user
        }
    }
}

