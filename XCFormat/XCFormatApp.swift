//
//  XCFormatApp.swift
//  XCFormat
//
//  Created by Steven Mok on 2018/8/2.
//  Copyright © 2018年 sugarmo. All rights reserved.
//

import AppKit
import SwiftUI

@main
struct XCFormatApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("XCFormat") {
            HomeView()
        }
        .defaultSize(width: HomeView.windowSize.width, height: HomeView.windowSize.height)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(after: .help) {
                Button("Email") {
                    appDelegate.feedbackWithEmail(NSApplication.shared)
                }

                Button("Twitter") {
                    appDelegate.feedbackWithTwitter(NSApplication.shared)
                }
            }
        }
    }
}
