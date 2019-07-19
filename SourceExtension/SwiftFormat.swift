//
//  SwiftFormat.swift
//  XCFormat
//
//  Created by Steven Mok on 2019/7/19.
//  Copyright © 2019 sugarmo. All rights reserved.
//

import Cocoa

enum SwiftFormat: Executable {
    static let supportedUTIs: Set<String> = ["public.swift-source", "com.apple.dt.playground", "com.apple.dt.playgroundpage"]

    static let configName: String = "swiftformat.json"

    static let docName: String = "swiftformat-doc.txt"

    static let execPath: String = Bundle.main.path(forResource: "swiftformat", ofType: nil)!

    static func makePathExtension(uti: String) -> String? {
        return "swift"
    }

    static func makeTaskArgs(uti: String, isFragmented: Bool, sourceFile: String) throws -> [String] {
        var args = [String]()

        if isFragmented {
            args.append(contentsOf: ["--fragment", "true"])
        }
        args.append(contentsOf: try makeOptions())
        args.append(contentsOf: ["--rules", try makeRules()])
        args.append(sourceFile)

        return args
    }

    static func makeRules() throws -> String {
        let configPath = try makeSharedConfigPath()

        let data = try Data(contentsOf: URL(fileURLWithPath: configPath))

        if let root = try JSONSerialization.jsonObject(with: data, options: []) as? [String: [String: Any]] {
            for (sectionName, sectionDict) in root {
                if sectionName == "rules", let dict = sectionDict as? [String: Bool] {
                    var rules = [String]()
                    for (ruleName, ruleEnabled) in dict {
                        if ruleEnabled {
                            rules.append(ruleName)
                        }
                    }
                    return rules.joined(separator: ",")
                }
            }
        }

        return ""
    }

    static func makeOptions() throws -> [String] {
        let configPath = try makeSharedConfigPath()

        let data = try Data(contentsOf: URL(fileURLWithPath: configPath))

        if let root = try JSONSerialization.jsonObject(with: data, options: []) as? [String: [String: Any]] {
            for (sectionName, sectionDict) in root {
                if sectionName == "options", let dict = sectionDict as? [String: String] {
                    var options = [String]()
                    for (optionName, optionValue) in dict {
                        options.append(optionName)
                        options.append(optionValue)
                    }
                    return options
                }
            }
        }

        return []
    }
}
