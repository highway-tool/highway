import XCTest
import Url

final class AbsoluteTests: XCTestCase {
    func testInitRelativeTo() {
        assertAbsoluteEqualsPath(Absolute(path: "test", relativeTo: "/"), "/test")
        assertAbsoluteEqualsPath(Absolute(path: "", relativeTo: "/"), "/")
        assertAbsoluteEqualsPath(Absolute(path: "hello/world", relativeTo: "/"), "/hello/world")
    }
    
    // We need the support for ".." in Absolute because sometimes we only get relative paths
    // containing ".." from tools like xcodebuild.
    func testInitRelativeTo_Dots() {
        assertAbsoluteEqualsPath(Absolute(path: "../xxx", relativeTo: "/Users/chris/project"), "/Users/chris/xxx")
    }
    
    func testAppendRelative() {
        let base = Absolute("/")
        let bin = base.appending(Relative("bin"))
        assertAbsoluteEqualsPath(bin, "/bin")
    }
}

private func assertAbsoluteEqualsPath(_ absoluteURL: Absolute, _ absolutePath: String, file: StaticString = #file, line: UInt = #line) {
    XCTAssertEqual(absoluteURL, Absolute(absolutePath), "\nURLs not equal:\n\(absoluteURL) \n\nExpected: \(absolutePath)", file: file, line: line)
}
