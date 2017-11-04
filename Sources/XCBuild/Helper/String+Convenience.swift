import Foundation

extension String {
    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var lines: [String] {
        var result = [String]()
        enumerateLines { (line, _) in
            result.append(line)
        }
        return result
    }
    
    var trimmedLines: [String] {
        return lines.trimmed
    }
}

extension Array where Iterator.Element == String {
    var trimmed: [String] {
        return map { $0.trimmed }
    }
}
