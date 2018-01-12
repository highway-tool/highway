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
    func text() -> Text {
        return Text(map { $0.text(indent: .whitespace(5)) + .newline })
    }
    
    public func printableString(with options: Print.Options) -> Text {
        return text().printableString(with: options)
    }
}

