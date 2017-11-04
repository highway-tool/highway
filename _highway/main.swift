import HighwayCore
import Foundation
import Terminal
import Arguments
import HighwayProject
import Git
import Url
import SwiftTool

extension GitAutotag {
    func getNextVersion(cwd: Absolute) throws -> String {
        return try autotag(at: cwd, dryRun: true)
    }
}

enum CustomHighway: String {
    case test, build, release, updateVersion, release_then_upload
}

final class App: Highway<CustomHighway> {
    override func setupHighways() {
        highway(.test, "Executed all unit and integration tests") ==> _test
        highway(.build, "Builds highway") ==> _build
        highway(.release, "Creates and publishes a new release").depends(on:  .test, .updateVersion, .build) ==> _release
        highway(.updateVersion, "Writes the next tag to CurrentVersion.swift and tags the current state.") ==> _commitUpdateVersionAndTag
        highway(.release_then_upload, "Creates and publishes a new release, then uploads it.") ==> _release_then_upload
        self.onError = _error
    }
    
    func _commitUpdateVersionAndTag() throws -> String {
        let nextVersion = try GitAutotag(system: system).getNextVersion(cwd: cwd)
        try update(nextVersion: nextVersion, currentDirectoryURL: cwd, fileSystem: fileSystem)
        
        try git.addAll(at: cwd)
        try git.commit(at: cwd, message: "Release \(nextVersion)")
        _ = try GitAutotag(system: system).autotag(at: cwd, dryRun: false)
        ui.message("New version: \(nextVersion)")
        return nextVersion
    }
    
    func _error(_ error: Swift.Error) {
        print(error)
        exit(EXIT_FAILURE)
    }
    
    func _test() throws {
        try swift.test(projectAt: cwd)
    }
    
    func _build() throws -> Artifact {
        let options = SwiftOptions(subject: .auto, configuration: .release, verbose: true, additionalArguments: [])
        return try swift.build(projectAt: cwd, options: options)
    }
    
    func _release() throws {
        ui.message("Releasing...")
    }
    
    func _release_then_upload() throws {
        try git.pushToMaster(at: cwd)
        try git.pushTagsToMaster(at: cwd)
    }
}

App(CustomHighway.self).go()
