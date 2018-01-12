import Foundation
import HighwayCore
import HWKit
import Terminal
import FileSystem
import Arguments
import HighwayProject
import POSIX
import Task

enum AppHighway: String {
    case initialize, help, generate, bootstrap, clean, version, self_update
}

func getPassword(for user: String) -> String? {
    let buf = [Int8](repeating: 0, count: 8192)
    guard let passwordData = readpassphrase("Password for '\(user)' (<enter> to continue): ", (UnsafeMutablePointer<Int8>)(mutating: buf), buf.count, 0) else { return nil }
    return String(validatingUTF8: passwordData)
}

final class App: Highway<AppHighway> {
    // MARK: Highway Overrides
    override func setupHighways() {
        highway(.initialize, "Initializes a new highway project", command: "init") ==> _init
        highway(.generate, "Generates an Xcode project")                     ==> _generate
        highway(.clean, "Delete build artifacts of your highway project")    ==> _clean
        highway(.self_update, "Updates highway & the supporting frameworks") ==> _self_update
        highway(.bootstrap, "Bootstraps the highway home directory")         ==> _bootstrap
        highway(.help, "Displays available commands and options")            ==> _showHelp

        onError = _handleError
        onEmptyCommand = _showHelp
        onUnrecognizedCommand = _fallbackCommand
    }
    
    // MARK: - Running highway
    override func didFinishLaunching(with invocation: Invocation) {
        ui.verbosePrint(Diagnostics(version: CurrentVersion, system: system))
        
        // Before anything happens try to ensure the credentials are okay.
        if let user = __projectDescription()?.credentials?.user {
            credentialStore.setUser(user)
            if credentialStore.password() == nil {
                ui.important("Your highway project seems to need credentials for '\(user)' but ")
                ui.important("no keychain item could be found for that user. Please enter a password/")
                ui.important("secret for '\(user)' and hit enter. highway will automatically create the")
                ui.important("corresponding keychain item for you. This has to be done only once.")
                if let pw = getPassword(for: user) {
                    try? credentialStore.setPassword(pw)
                }
            }
        }
    }
    
    // MARK: - Private Highways
    private func __customHighways() -> [HighwayDescription] {
        // Try to get the bundle
        // if the are not able to get it just show the help.
        guard let tool = try? __highwayProjectTool() else {
            return []
        }
        return tool.availableHighways()
    }
    
    @discardableResult
    private func __ensureValidHomeBundle() throws -> HomeBundle {
        let config = HomeBundle.Configuration.standard
        let homeDir = try fileSystem.homeDirectoryUrl()
        let highwayHomeDirectory = homeDir.appending(config.directoryName)
        let bootstrap = Bootstraper(homeDirectory: highwayHomeDirectory, configuration: config, git: git, fileSystem: fileSystem)
        return try bootstrap.requestHomeBundle()
    }
    
    // MARK: - Helper
    private func __highwayProjectTool() throws -> HighwayProjectTool {
        guard let bundle = __currentHighwayBundle() else {
            throw "Failed to get highway bundle."
        }
        
        return HighwayProjectTool(compiler: swift,
                                  bundle: bundle,
                                  system: system,
                                  fileSystem: fileSystem,
                                  verbose: verbose,
                                  ui: ui)

    }
    private func __projectDescription() -> ProjectDescription? {
        return try? __highwayProjectTool().projectDescription()
    }

    private func __currentHighwayBundle() -> HighwayBundle? {
        let parentUrl = abscwd()
        return try? HighwayBundle(fileSystem: fileSystem,
                                  parentUrl: parentUrl,
                                  configuration: .standard)
    }
    
    /// Updates the frameworks _highway is using.
    private func _updateDependencies() throws {
        guard let bundle = __currentHighwayBundle() else {
            ui.error("Update failed. No highway project found."); return
        }
        do {
            ui.message("Updating support frameworks…")
            let _highway = HighwayProjectTool(compiler: swift, bundle: bundle, system: system, fileSystem: fileSystem, verbose: verbose, ui: ui)
            try _highway.update()
            ui.success("Success")
        } catch {
            ui.error("Update failed. It happens…: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Custom Highways
    private func _init() throws {
        try self.__ensureValidHomeBundle()
        let projectBundle = try HighwayBundle(creatingInParent: abscwd(), fileSystem: fileSystem, configuration: .standard, homeBundleConfiguration: .standard)
        ui.success("Created at: \(projectBundle.url.lastPathComponent). Try 'highway generate'.")
    }
    
    private func _generate() throws {
        ui.message("Creating Xcode project\(String.elli)")
        guard let bundle = __currentHighwayBundle() else {
            ui.error("Cannot generate an Xcode project without a highway project")
            ui.error("present in the current working directory.")
            try _showHelp()
            return
        }
        let project = try XCProjectGenerator(swift: swift, bundle: bundle).generate()
        ui.success("Project '\(bundle.xcodeprojectUrl.lastPathComponent)' generated. Try:")
        ui.success("$ " + project.openCommand)
        ui.important("Hint: You have to change the scheme to '_highway' after opening the project.")
        
    }
    
    private func _update_highway() throws -> HomeBundle {
        let homeBundle = try self.__ensureValidHomeBundle()
        try HomeBundleUpdater(bundle: homeBundle, git: git, ui: ui).update()
        return homeBundle
    }
    
    private func _bootstrap() throws {
        let _ = try self.__ensureValidHomeBundle()
    }
    
    private func _clean() throws  {
        let config = HighwayBundle.Configuration.standard
        ui.message("Cleaning \(config.directoryName)\(String.elli)")
        guard let bundle = __currentHighwayBundle() else {
            ui.message("Nothing to do")
            return
        }
        let result = try bundle.clean()
        ui.success("DONE")
        let lines = result.deletedFiles.map { "Deleted '\($0.path)'" }
        let list = List(lines: lines)
        ui.print(list)
        ui.print(String.newline)
    }
    
    private func _self_update() throws {
        let homeBundle = try _update_highway()
        let updater = SelfUpdater(homeBundle: homeBundle, git: git, system: system)
        try updater.update()
        exit(EXIT_SUCCESS)
    }
    
    private func _handleError(error: Swift.Error) {
        var msg: String = ""
        dump(error, to: &msg)
        ui.error(msg)
        exit(EXIT_FAILURE)
    }
    
    // Try to forward args to the highway project.
    // If it does not exist help the user.
    private func _fallbackCommand(args: Arguments) throws {
        guard let bundle = __currentHighwayBundle() else {
            ui.error("No highway project found.")
            try _showHelp()
            return
        }
        let selfInvocation = CommandLineInvocationProvider().invocation()
        let arguments = [selfInvocation.highway] + selfInvocation.arguments.all
        let args = Arguments(arguments: arguments)
        let projectTool = HighwayProjectTool(compiler: swift, bundle: bundle, system: system, fileSystem: fileSystem, verbose: verbose, ui: ui)
        _ = try projectTool.build(thenExecuteWith: args)
    }
    
    private func _showHelp() throws {
        let info = appInfo(developerProvidedDescriptions: __customHighways())
        let prolog:Text =
            .newline +
                .whitespace(3) + .text("highway", color: .red, bold: true) +
                .whitespace(1) + .text("✱ Version \(CurrentVersion)", color: .none, bold: true) + .newline +
                .newline
        ui.print(prolog)
        ui.print(info)
    }
}
