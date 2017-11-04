import XCTest
@testable import Deliver
@testable import XCBuild

final class DestinationDetectionTests: XCTestCase {
    func test1() throws {
        let destinations = Destination.destinations(xcbuildOutput: fixture1)
        guard destinations.count == 2 else {
            XCTFail("wrong count")
            return
        }
        XCTAssertEqual(destinations[0].id, "AD911BF6-5421-47D3-AD80-DACBEB9B4B24")
        XCTAssertEqual(destinations[1].id, "EEDAA5DA-EC8D-4747-B96D-F6D16E1622B8")
    }
    
    func test2() throws {
        let destinations = Destination.destinations(xcbuildOutput: fixture2)
        XCTAssertTrue(destinations.isEmpty)
    }
    
    func test3() throws {
        let destinations = Destination.destinations(xcbuildOutput: fixture3)
        guard destinations.count == 2 else {
            XCTFail("wrong count")
            return
        }
        XCTAssertEqual(destinations[0].id, "F1ED5B2E-FCD2-414A-83E8-194EA496B91B")
        XCTAssertEqual(destinations[1].id, "EA60BBA3-4F0E-4FDA-95F7-1D9A404D033D")
    }
    
    func testEmptyInput() throws {
        let destinations = Destination.destinations(xcbuildOutput: "")
        XCTAssertTrue(destinations.isEmpty)
    }
    
    func testGarbageInput() throws {
        let destinations = Destination.destinations(xcbuildOutput: "dssdlk salkdjalskdklasdj a\nfddfdsfdsfdsfsdf334829748927489232\nnnnn")
        XCTAssertTrue(destinations.isEmpty)
    }
}

// MARK: Fixtures

/// Normal output from "my" machine.
private let fixture1 = """
xcodebuild: error: Unable to find a destination matching the provided destination specifier:
{ name:NoSuchName }

Unsupported device specifier option.
The device “My Mac” does not support the following options: name
Please supply only supported device specifier options.

Available destinations for the "highwayiostest" scheme:
{ platform:iOS Simulator, id:AD911BF6-5421-47D3-AD80-DACBEB9B4B24, OS:11.0.1, name:iPhone 7 }
{ platform:iOS Simulator, id:EEDAA5DA-EC8D-4747-B96D-F6D16E1622B8, OS:11.0.1, name:ipad }

Ineligible destinations for the "highwayiostest" scheme:
{ platform:iOS, id:dvtdevice-DVTiPhonePlaceholder-iphoneos:placeholder, name:Generic iOS Device }
{ platform:iOS Simulator, id:dvtdevice-DVTiOSDeviceSimulatorPlaceholder-iphonesimulator:placeholder, name:Generic iOS Simulator Device }

"""

/// Output if all simulators are removed
private let fixture2 = """
xcodebuild: error: Unable to find a destination matching the provided destination specifier:
{ name:NoSuchName }

Unsupported device specifier option.
The device “My Mac” does not support the following options: name
Please supply only supported device specifier options.

Ineligible destinations for the "highwayiostest" scheme:
{ platform:iOS, id:dvtdevice-DVTiPhonePlaceholder-iphoneos:placeholder, name:Generic iOS Device }
{ platform:iOS Simulator, id:dvtdevice-DVTiOSDeviceSimulatorPlaceholder-iphonesimulator:placeholder, name:Generic iOS Simulator Device }

"""

/// Output for simulators with different iOS versions
/// The available destinations depend on the target's deployment target.
/// For example if the deployment target is iOS 11 then every available destination
/// is at least iOS 11.
private let fixture3 = """
xcodebuild: error: Unable to find a destination matching the provided destination specifier:
{ name:NoSuchName }

Unsupported device specifier option.
The device “My Mac” does not support the following options: name
Please supply only supported device specifier options.

Available destinations for the "highwayiostest" scheme:
{ platform:iOS Simulator, id:F1ED5B2E-FCD2-414A-83E8-194EA496B91B, OS:10.3.1, name:iPhone 6 - 10.3 }
{ platform:iOS Simulator, id:EA60BBA3-4F0E-4FDA-95F7-1D9A404D033D, OS:11.0.1, name:iPhone 6 - 11 }

Ineligible destinations for the "highwayiostest" scheme:
{ platform:iOS, id:dvtdevice-DVTiPhonePlaceholder-iphoneos:placeholder, name:Generic iOS Device }
{ platform:iOS Simulator, id:dvtdevice-DVTiOSDeviceSimulatorPlaceholder-iphonesimulator:placeholder, name:Generic iOS Simulator Device }

"""

