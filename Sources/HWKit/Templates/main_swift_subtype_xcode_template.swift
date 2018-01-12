import Foundation

public let mainSwiftSubtypeXcodeTemplate =
"""
import HighwayCore
import XCBuild
import HighwayProject
import Deliver
import Foundation

enum Way: String { case test, build, run }

final class App: Highway<Way> {
    // MARK: - Setup
    override func setupHighways() {
        highway(.build, "Builds the project") ==> build
        highway(.test, "Executes tests") ==> test
        highway(.run, "Runs the project") ==> run
    }

    // MARK: - Highways

    // $ highway build
    func build() throws { /* intentionally left blank */ }

    // $ highway run
    func run() throws { /* intentionally left blank */ }

    // $ highway test
    func test() throws {
        var options = BuildOptions()
        options.project = "<insert path to *.xcproject here>"
        options.scheme = "<insert name of scheme here>"
        options.destination = Destination.simulator(.iOS, name: "iPhone 7", os: .latest, id: nil)
        try xcbuild.build(using: options, executeTests: true)
    }
}

App(Way.self).go()
"""
