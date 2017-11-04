import XCTest
import XCBuild
import FileSystem
import Url
import HighwayCore
@testable import Task
import Deliver
import TestKit
import Keychain
import Terminal

final class XCBuildTests: XCTestCase {
    // MARK: - XCTest
    /// We override invokeTest to disable tests in this file in case HIGHWAY_SYSTEM_TEST is not set.
    /// The system tests require a specific setup (profiles, certificates, ...) that is only present on 'my' machine.
    /// The tests also only work if there are two keychain items:
    /// - HIGHWAY_DELIVER_PASSWORD
    /// - HIGHWAY_DELIVER_USERNAME
    override func invokeTest() {
        if ProcessInfo.processInfo.environment["HIGHWAY_SYSTEM_TEST"] == nil {
            print("⚠️  HIGHWAY_SYSTEM_TEST not set: System Tests are not executed.")
        } else {
            print("✅  HIGHWAY_SYSTEM_TEST set: Executing test.\(invocation?.selector.description ?? "none")")
            guard let newCredentials = try? retrieveCredentials() else {
                XCTFail("Failed to get credentials")
                return
            }
            credentials = newCredentials
            super.invokeTest()
        }
    }
    
    override func setUp() {
        super.setUp()
        Terminal.shared.verbose = true
        let devDir = XCBuildTests._developerDirectory()
        let altoolProvider = Altool.executableProvider(developerDirectory: devDir, fileSystem: LocalFileSystem())
        self.system = LocalSystem.local(additionalProviders: [altoolProvider])
    }
    private var system = LocalSystem.local()
    
    private static func _developerDirectory() -> Absolute {
        let system = LocalSystem.local()
        let defaultDir: Absolute = "/Applications/Xcode.app/Contents/Developer"
        do {
            let xcrun = try system.task(named: "xcrun").dematerialize()
            xcrun.arguments.append(contentsOf: ["xcode-select", "-p"])
            xcrun.enableReadableOutputDataCapturing()
            try system.execute(xcrun).assertSuccess()
            guard let developerDirectory = xcrun.trimmedOutput else {
                return defaultDir
            }
            return Absolute(developerDirectory)
        } catch {
            return defaultDir
        }
    }
    
    // MARK: - Helper
    let fixturesDir = Absolute(URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("Fixtures"))
    let fs = LocalFileSystem()
    var credentials: Credentials = Credentials(username: "", password: "")
    struct Credentials { let username: String; let password: String }
    private func retrieveCredentials() throws -> Credentials {
        let keychain = Keychain(system: LocalSystem.local())
        do {
            let password = try keychain.password(matching: .init(account: "HIGHWAY_DELIVER_PASSWORD", service: "HIGHWAY_DELIVER_PASSWORD"))
            let username = try keychain.password(matching: .init(account: "HIGHWAY_DELIVER_USERNAME", service: "HIGHWAY_DELIVER_USERNAME"))
            return Credentials(username: username, password: password)
        } catch {
            XCTFail("Failed to get username/password from the Keychain. To resolve this issue disable the system tests (default) or create two Keychain items: HIGHWAY_DELIVER_PASSWORD and HIGHWAY_DELIVER_USERNAME.")
            XCTFail(error.localizedDescription)
            throw error
        }
    }

    // MARK: - Tests
    func test_test_action() throws {
        let provider = SystemExecutableProvider.local()
        provider.searchedUrls += ["/usr/local/bin/"] // a bit hacky - but that enables xcpretty
        system.executableProvider = provider
        let projectRoot = fixturesDir.appending("highwayiostest_objc")
        let projectUrl = projectRoot.appending("highwayiostest.xcodeproj")

        var options = BuildOptions()
        options.project = projectUrl
        options.scheme = "highwayiostest"
        
        let xcbuild = XCBuild(system: system, fileSystem: LocalFileSystem(), ui: Terminal.shared)
        try xcbuild.build(using: options, executeTests: true)
    }
    
    func testArchive_and_Export_using_object_plist() throws {
        let projectRoot = fixturesDir.appending("highwayiostest_objc")
        let build = XCBuild(system: system, fileSystem: fs, ui: Terminal.shared)

        let projectUrl = projectRoot.appending("highwayiostest.xcodeproj")
        try build.incrementBuildNumber(project: projectUrl, scheme: "highwayiostest")

        var options = ArchiveOptions()
        options.scheme = "highwayiostest"
        options.project = projectUrl
        options.archivePath = try fs.uniqueTemporaryDirectoryUrl().appending("uud.xcarchive")
        
        try build.archive(using: options)
        
        var exportArchiveOptions = ExportArchiveOptions()
        exportArchiveOptions.archivePath = options.archivePath
        exportArchiveOptions.exportPath = try fs.uniqueTemporaryDirectoryUrl()
        
        var exportOptions = ExportOptions()
        exportOptions.method = .appStore
        exportOptions.thinning = .all
        
        var profiles = ExportOptions.ProvisioningProfiles()
        profiles.addProfile(.named("highwayiostest Prod Profile"),
                            forBundleIdentifier: "de.christian-kienle.highway.e2e.ios")
        exportOptions.provisioningProfiles = profiles
        let plist = try Plist.plist(byWriting: exportOptions, to: fs)
        exportArchiveOptions.exportOptionsPlist = plist
        let export = try build.export(using: exportArchiveOptions)
        print("ipaUrl: \(export.ipaUrl)")
        let deliver = Deliver.Local(altool: Altool(system: system, fileSystem: fs))
        try deliver.now(with: Deliver.Options(ipaUrl: export.ipaUrl, username: credentials.username, password: .plain(credentials.password), platform: .iOS))
        print("DONE")
    }
    
    func testArchive_and_Export_using_file_plist() throws {
        let projectRoot = fixturesDir.appending("highwayiostest_objc")
        let projectUrl = projectRoot.appending("highwayiostest.xcodeproj")
        let build = XCBuild(system: system, fileSystem: fs, ui: Terminal.shared)
        try build.incrementBuildNumber(project: projectUrl, scheme: "highwayiostest")

        var options = ArchiveOptions()
        options.scheme = "highwayiostest"
        options.project = projectUrl
        options.destination = Destination.device(.iOS, name: nil, isGeneric: true, id: nil)
        options.archivePath = try fs.uniqueTemporaryDirectoryUrl().appending("uud.xcarchive")
        
        try build.archive(using: options)
        
        var exportArchiveOptions = ExportArchiveOptions()
        exportArchiveOptions.archivePath = options.archivePath
        exportArchiveOptions.exportPath = try fs.uniqueTemporaryDirectoryUrl()
        
        let plistUrl = Absolute(URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
            .appendingPathComponent("highwayiostest_export.plist"))
        
        exportArchiveOptions.exportOptionsPlist = try? Plist.plist(byReading: plistUrl, in: fs)
        
        let export = try build.export(using: exportArchiveOptions)
        print("ipaUrl: \(export.ipaUrl)")
        let deliver = Deliver.Local(altool: Altool(system: system, fileSystem: fs))
        try deliver.now(with: Deliver.Options(ipaUrl: export.ipaUrl, username: credentials.username, password: .plain(credentials.password), platform: .iOS))
        print("DONE")
    }
}
