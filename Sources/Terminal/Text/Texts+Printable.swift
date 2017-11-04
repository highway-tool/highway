import Foundation

extension String: Printable {
    public func printableString(with options: Print.Options) -> Text {
        return Text(self)
    }
}

extension SubText: Printable {
    public func printableString(with options: Print.Options) -> Text {
        return Text(self)
    }
}

extension Text: Printable {
    public func printableString(with options: Print.Options) -> Text {
        return self
    }
}
