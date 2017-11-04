import Foundation
import Arguments
import Url
import Task
import POSIX
import Terminal

public struct Diagnostics {
    // MARK: - Properties
    let arguments: Arguments
    let version: String?
    let cwd: Absolute
    let environment: Environment
    let path: PathEnv
    let tools: [Tool]
    
    // MARK: - Init
    public init(version: String?, tools: [Tool]) {
        let env = ProcessInfo.processInfo.environment
        environment = Environment(all: env)
        arguments = Arguments(CommandLine.arguments)
        self.version = version
        cwd = abscwd()
        path = PathEnv(environment: env, cwd: cwd)
        self.tools = tools
    }
    
    public init(version: String?, system: System) {
        let rawTools = ["git", "xcpretty", "git-autotag", "bash", "sleep", "security", "xcrun", "altool"]
        let tools:[Tool] = rawTools.map { Tool(name: $0, system: system) }
        self.init(version: version, tools: tools)
    }
}

extension Diagnostics: Printable {
    private func text(with options: Print.Options) -> Text {
        var table = Table(width: 80)
        
        table.addEmptyRows(2)
        environment.addTo(table: &table)
        table.addEmptyRows(2)

        table.addFullWidthRow(SubText("Search URLs".uppercased(), color: .yellow), alignment: .center)
        table.addFullWidthBoldSeparator()
        path.searchUrls.forEach { searchUrl in
            table.addFullWidthRow(SubText(searchUrl.path))
        }
        table.addEmptyRows(2)
        table.addFullWidthRow(SubText("Arguments".uppercased(), color: .yellow), alignment: .center)
        table.addFullWidthBoldSeparator()
        arguments.loggableValues.forEach { arg in
            table.addFullWidthRow(SubText(arg))
        }
        table.addEmptyRows(2)
        table.addFullWidthRow(SubText("Other Properties".uppercased(), color: .yellow), alignment: .center)
        table.addFullWidthBoldSeparator()
        table.add(Row(values: [.init(width: 40, text: SubText("cwd")),
                               .init(width: 40, text: SubText(cwd.path))]))
        table.add(Row(values: [.init(width: 40, text: SubText("Version")),
                               .init(width: 40, text: SubText(version ?? "<none - WTF?>"))]))
        
        table.addEmptyRows(2)
        table.addFullWidthRow(SubText("Tools".uppercased(), color: .yellow), alignment: .center)
        table.addFullWidthBoldSeparator()
        tools.forEach {
            $0.addTo(table: &table)
        }
        table.addEmptyRows(4)
        return table.text()
    }
    
    public func printableString(with options: Print.Options) -> Text {
        return text(with: options).printableString(with: options)
    }
}

extension Diagnostics {
    public struct Tool {
        // MARK: - Properties
        let name: String
        let path: Absolute?
        
        // MARK: - Init
        init(name: String, system: System) {
            self.init(name: name, path: system.task(named: name).value?.executableUrl)
        }
        
        init(name: String, path: Absolute?) {
            self.name = name
            self.path = path
        }
    }
}

extension Diagnostics.Tool {
    func addTo(table: inout Table) {
        let pathText = (path.map { path in SubText(path.path, color: .none) }) ?? SubText("<not found>", color: .red)
        
        table.add(Row(values: [.init(width: 40, text: SubText(name, color: .none)),
                               .init(width: 40, text: pathText)]))
    }
}

extension Diagnostics {
    struct PathEnv {
        init(raw: String?, searchUrls: [Absolute]) {
            self.raw = raw
            self.searchUrls = searchUrls
        }
        
        init(environment: [String: String], cwd: Absolute) {
            let urls = PathEnvironmentParser.local().urls
            self.init(raw: environment["PATH"], searchUrls: urls)
        }
        let raw: String?
        let searchUrls: [Absolute]
    }
}

extension Diagnostics {
    struct Environment {
        // MARK: - Init
        init(all: [String: String]) {
            highway = all.filter { $0.key.isHighwayEnvironmentVariable }
            other = all.filter { !$0.key.isHighwayEnvironmentVariable }
        }
        
        // MARK: - Properties
        let highway: [String: String]
        let other: [String: String]
    }
}

extension Diagnostics.Environment {
    func addTo(table: inout Table) {
        table.addFullWidthRow(SubText("Environment Variables".uppercased(), color: .yellow), alignment: .center)
        table.addFullWidthBoldSeparator()
        for env in other {
            table.add(Row(values: [.init(width: 40, text: SubText(env.key)),
                                   .init(width: 40, text: SubText(env.value))]))
        }
        for env in highway {
            table.add(Row(values: [.init(width: 40, text: SubText(env.key, color: .magenta)),
                                   .init(width: 40, text: SubText(env.value, color: .magenta))]))
        }
    }
}


fileprivate extension String {
    private static let HighwayPrefix = "HIGHWAY_"
    var isHighwayEnvironmentVariable: Bool {
        return uppercased().hasPrefix(.HighwayPrefix)
    }
}
