//
//  SwiftFormat.swift
//  SourceExtension
//
//  Created by Steven Mok on 2019/7/12.
//  Copyright © 2019 sugarmo. All rights reserved.
//

import Cocoa

protocol TaskArgProvider {
    static func makeTaskArgs(uti: String, isFragmented: Bool, sourceFile: String) throws -> [String]
}

protocol UserCustomizable {
    static var configName: String { get }

    static var docName: String { get }
}

extension UserCustomizable {
    //    static func makeAppSupportDirectoryPath() -> String? {
    //        if let path = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first {
    //            return path
    //        }
    //        return nil
    //    }

    static func makeSharedConfigPath() throws -> String {
        guard let groupPath = AppGroup.makeRootPath() else {
            throw FormatterError.missingFile
        }

        let configsPath = groupPath.bridged().appendingPathComponent("Configs")

        if !FileManager.default.fileExists(atPath: configsPath) {
            try FileManager.default.createDirectory(atPath: configsPath, withIntermediateDirectories: true, attributes: nil)
        }

        let sharedConfigPath = configsPath.bridged().appendingPathComponent(configName)

        if !FileManager.default.fileExists(atPath: sharedConfigPath) {
            if let configTemplatePath = Bundle.main.path(forResource: configName, ofType: nil) {
                try FileManager.default.copyItem(atPath: configTemplatePath, toPath: sharedConfigPath)
            }
        }

        let sharedDocPath = configsPath.bridged().appendingPathComponent(docName)

        if !FileManager.default.fileExists(atPath: sharedDocPath) {
            if let docSourcePath = Bundle.main.path(forResource: docName, ofType: nil) {
                try FileManager.default.copyItem(atPath: docSourcePath, toPath: sharedDocPath)
            }
        }

        return sharedConfigPath
    }
}

enum Uncrustify: UserCustomizable, TaskArgProvider {
    static let configName: String = "uncrustify.cfg"

    static let docName: String = "uncrustify-doc.txt"

    static let execPath: String = Bundle.main.path(forResource: "uncrustify", ofType: nil)!

    static func makeTaskArgs(uti: String, isFragmented: Bool, sourceFile: String) throws -> [String] {
        var args = [String]()

        args.append("--no-backup")

        let isObjectiveCFile = NSWorkspace.shared.type(uti, conformsToType: kUTTypeObjectiveCSource as String) ||
            NSWorkspace.shared.type(uti, conformsToType: kUTTypeCHeader as String)
        if isObjectiveCFile {
            args.append(contentsOf: ["-l", "OC"])
        }

        if isFragmented {
            args.append("--frag")
        }

        args.append(contentsOf: ["-c", try makeSharedConfigPath()])

        args.append(sourceFile)

        return args
    }
}

enum SwiftFormat: UserCustomizable, TaskArgProvider {
    static let configName: String = "swiftformat.json"

    static let docName: String = "swiftformat-doc.txt"

    static let execPath: String = Bundle.main.path(forResource: "swiftformat", ofType: nil)!

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
