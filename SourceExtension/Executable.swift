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

    static var execPath: String { get }

    static func makeTaskArgs(uti: String, isFragmented: Bool, sourceFile: String) throws -> [String]

    static func makePathExtension(uti: String) -> String?
}

extension Executable {
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
