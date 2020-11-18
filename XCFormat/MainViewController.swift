//
//  MainViewController.swift
//  XCFormat
//
//  Created by Steven Mok on 2018/8/2.
//  Copyright © 2018年 sugarmo. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController {
    // MARK: - SwiftFormat

    @IBAction func swiftFormatConfig(_ sender: Any) {
        if let path = SwiftFormat.userConfigPath(createDirectoryIfAbsent: true) {
            NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
        }
    }

    @IBAction func swiftFormatReset(_ sender: Any) {
        SwiftFormat.resetConfigToDefault()
    }

    @IBAction func swiftFormatView(_ sender: Any) {
        if let url = SwiftFormat.websiteURL {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Uncrustify

    @IBAction func uncrustifyConfig(_ sender: Any) {
        if let path = Uncrustify.userConfigPath(createDirectoryIfAbsent: true) {
            NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
        }
    }

    @IBAction func uncrustifyReset(_ sender: Any) {
        Uncrustify.resetConfigToDefault()
    }

    @IBAction func uncrustifyView(_ sender: Any) {
        if let url = Uncrustify.websiteURL {
            NSWorkspace.shared.open(url)
        }
    }
}
