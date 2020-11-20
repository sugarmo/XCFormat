//
//  SwiftFormat.swift
//  XCFormat
//
//  Created by Steven Mok on 2019/7/19.
//  Copyright © 2019 sugarmo. All rights reserved.
//

import Cocoa
import Yams

enum SwiftFormat: Executable {
//    enum OptionValue: Codable, CustomStringConvertible {
//        case string(String)
//        case int(Int)
//        case bool(Bool)
//
//        init(from decoder: Decoder) throws {
//            let container = try decoder.singleValueContainer()
//            let stringValue = try container.decode(String.self)
//
//            if let boolValue = try? container.decode(Bool.self) {
//                self = .bool(boolValue)
//            } else if let intValue = try? container.decode(Int.self) {
//                self = .int(intValue)
//            } else {
//                self = .string(stringValue)
//            }
//        }
//
//        func encode(to encoder: Encoder) throws {
//            var container = encoder.singleValueContainer()
//
//            switch self {
//            case let .string(value):
//                try container.encode(value)
//            case let .int(value):
//                try container.encode(value)
//            case let .bool(value):
//                try container.encode(value)
//            }
//        }
//
//        var description: String {
//            switch self {
//            case let .string(value):
//                return value
//            case let .int(value):
//                return "\(value)"
//            case let .bool(value):
//                return value ? "true" : "false"
//            }
//        }
//    }
//
//    struct YAMLConfig: Codable {
//        var rules: [String]
//        var options: [String: OptionValue]
//
//        func append(toArgs args: inout [String]) {
//            args.append("--rules")
//            args.append(rules.joined(separator: ","))
//
//            for option in options {
//                args.append("--\(option.key)")
//                args.append(option.value.description)
//            }
//        }
//    }
    struct Config: Codable {
        var rules: [String]
        var options: [String: String]

        func append(toArgs args: inout [String]) {
            args.append("--rules")
            args.append(rules.joined(separator: ","))

            for option in options {
                args.append("--\(option.key)")
                args.append(option.value)
            }
        }

        func migratedFromJSON() -> Config {
            var newOptions = [String: String]()
            for each in options {
                if each.key.hasPrefix("--") {
                    let key = String(each.key.dropFirst(2))
                    newOptions[key] = each.value
                }
            }
            return Config(rules: rules, options: newOptions)
        }
    }

    static let supportedUTIs: Set<String> = ["public.swift-source", "com.apple.dt.playground", "com.apple.dt.playgroundpage"]

    static let configName: String = "swiftformat.yaml"

    static let docName: String = "swiftformat-doc.txt"

    static let websiteURL = URL(string: "https://github.com/nicklockwood/SwiftFormat")

    static let execPath: String = Bundle.main.path(forResource: "swiftformat", ofType: nil)!

    static func makePathExtension(uti: String) -> String? {
        return "swift"
    }

    static func makeTaskArgs(uti: String, isFragmented: Bool, sourceFile: String) throws -> [String] {
        var args = [String]()

        if isFragmented {
            args.append(contentsOf: ["--fragment", "true"])
        }

        try readUserConfig().append(toArgs: &args)

        args.append(sourceFile)

        return args
    }

    static func readUserConfig() throws -> Config {
        let configPath = try prepareUserConfig()
        let configURL = URL(fileURLWithPath: configPath)
        let data = try Data(contentsOf: configURL)
        return try YAMLDecoder().decode(Config.self, from: data)
    }

    static func writeUserConfig(_ config: Config) throws {
        if let configPath = userConfigPath(createDirectoryIfAbsent: true) {
            let yamlString = try YAMLEncoder().encode(config)
            try yamlString.write(to: URL(fileURLWithPath: configPath), atomically: true, encoding: .utf8)
        } else {
            throw FormatterError.failure(reason: "User config path not found.")
        }
    }

    static func appDidLaunch() {
        removeUserDoc()
        upgradeUserConfig()
    }
}

extension SwiftFormat {
    private struct JSONConfig_V1: Codable {
        var rules: [String: Bool]
        var options: [String: String]

        func migrated() -> Config {
            let rules = self.rules.compactMap { ele -> String? in
                // ranges 不是一个 rule，但过去的配置文件写错进去了
                if ele.value, ele.key != "ranges" {
                    return ele.key
                }
                return nil
            }

            var newOptions = [String: String]()
            for each in options {
                if each.key.hasPrefix("--") {
                    let key = String(each.key.dropFirst(2))
                    newOptions[key] = each.value
                }
            }

            return Config(rules: rules, options: newOptions)
        }
    }

    private static let jsonConfigName: String = "swiftformat.json"

    private static var jsonUserConfigPath: String? {
        userConfigsDirectory()?.bridged.appendingPathComponent(jsonConfigName)
    }

    private static func readJSONUserConfig<T>(of type: T.Type) -> T? where T: Decodable {
        guard let configPath = jsonUserConfigPath?.fileExisting else {
            return nil
        }

        do {
            let configURL = URL(fileURLWithPath: configPath)
            let configData = try Data(contentsOf: configURL)
            return try JSONDecoder().decode(T.self, from: configData)
        } catch {
            return nil
        }
    }

    private static func removeJSONUserConfig() {
        guard let configPath = jsonUserConfigPath?.fileExisting else {
            return
        }
        try? FileManager.default.removeItem(atPath: configPath)
    }

    private static func upgradeUserConfig() {
        // check if not yaml format
        if userConfigPath()?.fileExisting == nil {
            if let legacyConfig = readJSONUserConfig(of: JSONConfig_V1.self) {
                try? writeUserConfig(legacyConfig.migrated())
            } else if let jsonConfig = readJSONUserConfig(of: Config.self) {
                try? writeUserConfig(jsonConfig.migratedFromJSON())
            }
        }

        removeJSONUserConfig()
    }
}
