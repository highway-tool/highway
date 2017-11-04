import Foundation
infix operator <<< : StreamingPrecedence
precedencegroup StreamingPrecedence {
    associativity: left
}
extension Text {
    public static func +(l: Text, r: Text) -> Text {
        return l.appending(r)
    }
    
    public static func <<<(l: Text, r: SubText) -> Text {
        return l.appending(string: r)
    }
}
