//
//  SwiftFormat.swift
//  SourceExtension
//
//  Created by Steven Mok on 2019/7/12.
//  Copyright © 2019 sugarmo. All rights reserved.
//

import Cocoa

protocol Executable {
    static var configName: String { get }

    static var docName: String { get }

    static var websiteURL: URL? { get }

    static var execPath: String { get }

    static func makeTaskArgs(uti: String, isFragmented: Bool, sourceFile: String) throws -> [String]

    static func makePathExtension(uti: String) -> String?

    static func appDidLaunch()
}

extension Executable {
    //    static func makeAppSupportDirectoryPath() -> String? {
    //        if let path = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first {
    //            return path
    //        }
    //        return nil
    //    }

    static func userConfigsDirectory(createIfAbsent: Bool = false) -> String? {
        guard let appGroupPath = AppGroup.makeRootPath() else {
            return nil
        }

        let path = appGroupPath.bridged.appendingPathComponent("Configs")

        if createIfAbsent, !FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                return nil
            }
        }

        return path
    }

    static func defaultConfigPath() -> String? {
        Bundle.main.path(forResource: configName, ofType: nil)
    }

    static func userConfigPath(createDirectoryIfAbsent: Bool = false) -> String? {
        userConfigsDirectory(createIfAbsent: createDirectoryIfAbsent)?.bridged.appendingPathComponent(configName)
    }

    static func docPath() -> String? {
        Bundle.main.path(forResource: docName, ofType: nil)
    }

    static func resetConfigToDefault() {
        guard let source = defaultConfigPath() else {
            return
        }

        if let destination = userConfigPath(createDirectoryIfAbsent: true) {
            try? FileManager.default.removeItem(atPath: destination)
            try? FileManager.default.copyItem(atPath: source, toPath: destination)
        }
    }

    static func prepareUserConfig() throws -> String {
        guard let destination = userConfigPath(createDirectoryIfAbsent: true) else {
            throw FormatterError.failure(reason: "Config file not found.")
        }

        if !FileManager.default.fileExists(atPath: destination) {
            guard let source = defaultConfigPath() else {
                throw FormatterError.failure(reason: "Default config file not found.")
            }

            do {
                try FileManager.default.copyItem(atPath: source, toPath: destination)
            } catch {
                throw FormatterError.failure(reason: "Copy default config file failed.")
            }
        }

        return destination
    }

    static func removeUserDoc() {
        if let userDocPath = userConfigsDirectory()?.bridged.appendingPathComponent(docName) {
            try? FileManager.default.removeItem(atPath: userDocPath)
        }
    }
}
