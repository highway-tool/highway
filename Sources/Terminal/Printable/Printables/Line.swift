import Foundation

public struct Line {
    // MARK: - Init
    public init(prompt: Prompt, text: Text) {
        self.prompt = prompt
        self.text = text
    }
    
    // MARK: - Properties
    public let prompt: Prompt
    public let text: Text
}

extension Line: Printable {
    public func printableString(with options: Print.Options) -> Text {
        return prompt.printableString(with: options) + text
    }
}
