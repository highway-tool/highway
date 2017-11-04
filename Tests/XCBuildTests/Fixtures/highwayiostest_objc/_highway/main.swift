import HighwayCore
import XCBuild
import HighwayProject
import Deliver
import Foundation
import Keychain

enum Way: String {
    case test, build, run, release, increase_build_number
}

class App: Highway<Way> {
    override func setupHighways() {
        highway(.build, "Builds the project") ==> build
        highway(.test, "Executes tests") ==> test
        highway(.run, "Runs the project") ==> run
        highway(.release, "Releases the App").depends(on: .increase_build_number) ==> release
        highway(.increase_build_number, "Increases the build number") ==> increaseBuildNumber

    }

    // MARK: - Highways
    func build() throws {

    }
    
    func increaseBuildNumber() throws {
        let projectUrl = cwd.appending("highwayiostest.xcodeproj")
        let scheme = "highwayiostest"
        
        let buildNumber = try xcbuild.incrementBuildNumber(project: projectUrl, scheme: scheme)
        ui.important("Previous Build Number: \(buildNumber.previous)")
        ui.important("Current Build Number: \(buildNumber.current)")
    }
    

    func release() throws {
        let projectUrl = cwd.appending("highwayiostest.xcodeproj")
        let scheme = "highwayiostest"
        let archiveLog = cwd.appending("archive.log")
        try fileSystem.writeData(Data(), to: archiveLog)
        var options = ArchiveOptions()
        options.scheme = scheme
        options.project = projectUrl
        options.archivePath = try fileSystem.uniqueTemporaryDirectoryUrl().appending("uud.xcarchive")
        options.logDestination = .file(archiveLog)
        try xcbuild.archive(using: options)
        
        var exportArchiveOptions = ExportArchiveOptions()
        exportArchiveOptions.archivePath = options.archivePath
        exportArchiveOptions.exportPath = try fileSystem.uniqueTemporaryDirectoryUrl()
        
        var exportOptions = ExportOptions()
        exportOptions.method = .appStore
        exportOptions.thinning = .all
        
        var profiles = ExportOptions.ProvisioningProfiles()
        profiles.addProfile(.named("highwayiostest Prod Profile"),
                            forBundleIdentifier: "de.christian-kienle.highway.e2e.ios")
        exportOptions.provisioningProfiles = profiles
        let plist = try Plist.plist(byWriting: exportOptions, to: fileSystem)
        exportArchiveOptions.exportOptionsPlist = plist
        let export = try xcbuild.export(using: exportArchiveOptions)
        print("ipaUrl: \(export.ipaUrl)")
        let credentials = try _credentials()
        try deliver.now(with: Deliver.Options(ipaUrl: export.ipaUrl, username: credentials.username, password: .plain(credentials.password), platform: .iOS))
        print("DONE")

    }
    
    func test() throws {
        let projectUrl = cwd.appending("highwayiostest.xcodeproj")
        let scheme = "highwayiostest"
        var options = TestOptions()
        options.project = projectUrl
        options.scheme = scheme
        try xcbuild.buildAndTest(using: options)
    }

    func run() throws {

    }
    struct Credentials { let username: String; let password: String }
    
    private func _credentials() throws -> Credentials {
        let password = try keychain.password(matching: .init(account: "HIGHWAY_DELIVER_PASSWORD", service: "HIGHWAY_DELIVER_PASSWORD"))
        let username = try keychain.password(matching: .init(account: "HIGHWAY_DELIVER_USERNAME", service: "HIGHWAY_DELIVER_USERNAME"))
        return Credentials(username: username, password: password)
    }

}

App(Way.self).go()
fflush(stdout)

