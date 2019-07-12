//
//  MainViewController.swift
//  XCFormat
//
//  Created by Steven Mok on 2018/8/2.
//  Copyright © 2018年 sugarmo. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController {
    @IBAction func editUncrustifyConfig(_ sender: Any) {
        if let path = try? Uncrustify.makeSharedConfigPath() {
            NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
        }
    }

    @IBAction func editSwiftFormatConfig(_ sender: Any) {
        if let path = try? SwiftFormat.makeSharedConfigPath() {
            NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
        }
    }

    @IBAction func quit(_ sender: Any) {
        NSApp.terminate(sender)
    }
}
