//
//  TextView.swift
//  Terminal
//
//  Created by Kienle, Christian on 30.10.17.
//

import Foundation

public struct Label {
    public init(_ text: String) {
        self.text = text
    }
    public var text: String
}

extension String {
    var words: [String] {
        return substrings(options: .byWords)
    }
    var lines: [String] {
        return substrings(options: .byLines)
    }
    func substrings(options: EnumerationOptions) -> [String] {
        var result = [String]()
        enumerateSubstrings(in: (startIndex..<endIndex), options: options) { (word, wordRange, _, _) in
            guard let word = word else { return }
            result.append(word)
        }
        return result
    }
}

public struct Table {
    public let width: Int
    public init(width: Int) {
        self.width = width
    }
    public var rows = [Row]()

    public mutating func add(_ row: Row) {
        add(rowsIn: [row])
    }
    public mutating func add(rowsIn rowArray: [Row]) {
        rows += rowArray
    }
    public enum Alignment {
        case left, center
    }
    public mutating func addFullWidthRow(_ text: SubText, alignment: Alignment = .left) {
        let _text: SubText
        switch alignment {
        case .left:
            _text = text
        case .center:
            _text = text.wrappedInWhitespace(toLength: width)
        }
        add(Row(values: [.init(width: width, text: _text)]))
    }
    public mutating func addRowsFor(key: SubText, keyWidth: Int, values: [SubText], valuesWidth: Int) {
        let keyRowValueText = values.first ?? SubText("<none>")
        let keyRow = Row(values: [.init(width: keyWidth, text: key),
                                  .init(width: valuesWidth, text: keyRowValueText)])

        let otherRows = values.dropFirst().map {
            Row(values: [.init(width: keyWidth, text: SubText(" ")),
                         .init(width: valuesWidth, text: $0)])
        }
        
        add(rowsIn: [keyRow] + otherRows)
    }
    public mutating func addEmptyRow() {
        addFullWidthRow(SubText(String(repeatElement(" ", count: width))))
    }
    public mutating func addEmptyRows(_ count: Int) {
        let text = SubText(String.whitespace(width))
        let value = Row.Value(width: width, text: text)
        let row = Row(values: [value])
        let rows = Array(repeating: row, count: count)
        add(rowsIn: rows)
    }

    public mutating func addFullWidthSeparator() {
        addFullWidthRow(SubText(String(repeatElement("-", count: width))))
    }
    public mutating func addFullWidthBoldSeparator() {
        addFullWidthRow(SubText(String(repeatElement("=", count: width))))
    }

    public func text() -> Text {
        let texts = rows.map { $0.text() }
        let withNL = texts.joined(separator: Text.newline)
        return Text(Array(withNL))
    }
}
public struct Column {
    public init(width: Int, title: SubText) {
        self.width = width
        self.title = title
    }
    public var width: Int
    public var title: SubText
}

public struct Row {
    public struct Value {
        public init(width: Int, text: SubText) {
            self.width = width
            self.text = text
        }
        public var width: Int
        public var text: SubText
    }
    public init(values: [Value]) {
        self.values = values
    }
    
    public var values: [Value]
    public func text() -> Text {
        let paddedValues:[SubText] = values.map { value in
            value.text.padding(toLength: value.width)
        }
        return Text(paddedValues)
    }
}

extension String {
    func padding(toLength length: Int) -> String {
        return (self as NSString).padding(toLength: length, withPad: " ", startingAt: 0)
    }
    func wrappedInWhitespace(toLength length: Int) -> String {
        let spaceLeft = max(length - count, 0)
        let ws = String.whitespace(spaceLeft / 2)
        return ws + self + ws
    }
}

extension SubText {
    func wrappedInWhitespace(toLength length: Int) -> SubText {
        var result = self
        result.text = result.text.wrappedInWhitespace(toLength: length)
        return result
    }
    func padding(toLength length: Int) -> SubText {
        var result = self
        result.text = result.text.padding(toLength: length)
        return result
    }
}

