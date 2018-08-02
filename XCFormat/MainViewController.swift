//
//  MainViewController.swift
//  XCFormat
//
//  Created by Steven Mok on 2018/8/2.
//  Copyright © 2018年 sugarmo. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController {
    @IBAction func editConfig(_ sender: Any) {
        if let plugInsPath = Bundle.main.builtInPlugInsPath, FileManager.default.fileExists(atPath: plugInsPath) {
            if let plugInsBundle = Bundle(path: plugInsPath) {
                if let exPath = plugInsBundle.path(forResource: "SourceExtension", ofType: "appex") {
                    if let exbundle = Bundle(path: exPath) {
                        if let cfgPath = exbundle.path(forResource: "uncrustify", ofType: "cfg") {
                            NSWorkspace.shared.selectFile(cfgPath, inFileViewerRootedAtPath: "")
                        }
                    }
                }
            }
        }
    }

    @IBAction func quit(_ sender: Any) {
        NSApp.terminate(sender)
    }
}
