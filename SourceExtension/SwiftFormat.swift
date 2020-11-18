//
//  SwiftFormat.swift
//  XCFormat
//
//  Created by Steven Mok on 2019/7/19.
//  Copyright © 2019 sugarmo. All rights reserved.
//

import Cocoa

enum SwiftFormat: Executable {
    struct LegacyConfig: Codable {
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

            return Config(rules: rules, options: options)
        }
    }

    struct Config: Codable {
        var rules: [String]
        var options: [String: String]

        func append(toArgs args: inout [String]) {
            args.append("--rules")
            args.append(rules.joined(separator: ","))

            for option in options {
                args.append(option.key)
                args.append(option.value)
            }
        }
    }

    static let supportedUTIs: Set<String> = ["public.swift-source", "com.apple.dt.playground", "com.apple.dt.playgroundpage"]

    static let configName: String = "swiftformat.json"

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

        try makeConfig().append(toArgs: &args)

        args.append(sourceFile)

        return args
    }

    static func makeConfig() throws -> Config {
        let configPath = try prepareUserConfig()
        let configURL = URL(fileURLWithPath: configPath)
        let data = try Data(contentsOf: configURL)

        return try JSONDecoder().decode(Config.self, from: data)
    }

    static func appDidLaunch() {
        removeUserDoc()

        // migrate old config
        if let configPath = userConfigPath() {
            do {
                let configURL = URL(fileURLWithPath: configPath)
                let existData = try Data(contentsOf: configURL)
                let oldConfig = try JSONDecoder().decode(LegacyConfig.self, from: existData)
                print("If no error, that means need to migrate old config.")
                let newConfig = oldConfig.migrated()
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let newData = try encoder.encode(newConfig)
                try newData.write(to: configURL)
            } catch {
                print(error)
            }
        }
    }
}
