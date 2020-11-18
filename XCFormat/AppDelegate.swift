//
//  AppDelegate.swift
//  XCFormat
//
//  Created by Steven Mok on 2018/8/2.
//  Copyright © 2018年 sugarmo. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        SwiftFormat.appDidLaunch()
        Uncrustify.appDidLaunch()
    }

//    func applicationWillTerminate(_ aNotification: Notification) {
//        // Insert code here to tear down your application
//    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    @IBAction func feedbackWithEmail(_ sender: Any) {
        let emailBody = ""
        let emailService = NSSharingService(named: .composeEmail)!
        emailService.recipients = ["xcformat@su9ar.com"]
        emailService.subject = "XCFormat Feedback"

        if emailService.canPerform(withItems: [emailBody]) {
            // email can be sent
            emailService.perform(withItems: [emailBody])
        } else {
            if let url = URL(string: "mailto:xcformat@su9ar.com") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    @IBAction func feedbackWithTwitter(_ sender: Any) {
        if let url = URL(string: "https://twitter.com/sugarmo87") {
            NSWorkspace.shared.open(url)
        }
    }
}
