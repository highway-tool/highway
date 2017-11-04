import XCTest
import Arguments

private class Person {
    var firstName: String?
    var lastName: String?
    var age: Int?
}

final class ArgumentsTests: XCTestCase {
    func testExample() {
        let p = Person()
        let parser = Parser(p)
        parser.add(Key<String>("--firstname", "-fn", description: "Sets the first name.")) { (pers, keyable) in
            pers.firstName = keyable
        }
        XCTAssertNoThrow(try parser.consume(["--firstname", "Chris"]))
        print(p)
    }
    func testEmptyArgs() {
        XCTAssert(Arguments(["hello", "", "world"]) == Arguments(["hello", "world"]))
        var args = Arguments()
        args += ["Hello"]
        args += [""]
        args += ["World"]
        XCTAssert(args == Arguments(["Hello", "World"]))

    }
}
