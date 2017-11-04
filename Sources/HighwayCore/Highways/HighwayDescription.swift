import Foundation
import Terminal

/// Describes a Highway.
public struct HighwayDescription: Codable {
    // MARK: - Properties
    public let name: String
    public let usage: String?

    // MARK: - Init
    init(name: String, usage: String?) {
        self.name = name
        self.usage = usage
    }
}


extension HighwayDescription {
    func text(indent: Text) -> Text {
        let usage = self.usage ?? "No usage text provided."
        let line1 = indent + .text("- ") + .text(usage + ":", color: .green) + .newline
        let line2 = indent + .whitespace(2) + .text("highway", color: .cyan) + .whitespace() + .text(name, color: .none) + .whitespace() + .newline
        return Text([line1, line2])
    }
}

extension Array where Iterator.Element == HighwayDescription {
    public func jsonString() throws -> String {
        let coder = JSONEncoder()
        let data = try coder.encode(self)
        guard let string = String(data: data, encoding: .utf8) else {
            throw "Failed to convert data to String."
        }
        return string
    }
    
    public init(rawHighwaysData data: Data) throws {
        let coder = JSONDecoder()
        let rawHighways = try coder.decode(type(of: self), from: data)
        self.init(rawHighways)
    }
    
    func text() -> Text {
        return Text(map { $0.text(indent: .whitespace(5)) + .newline })
    }
    
    public func printableString(with options: Print.Options) -> Text {
        return text().printableString(with: options)
    }
}

