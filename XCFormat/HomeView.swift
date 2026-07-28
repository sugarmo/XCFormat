//
//  HomeView.swift
//  XCFormat
//
//  Created by Steven Mok on 2018/8/2.
//  Copyright © 2018年 sugarmo. All rights reserved.
//

import AppKit
import SwiftUI

struct HomeView: View {
    static let windowSize = CGSize(width: 680, height: 420)

    var body: some View {
        TabView {
            XCFormatTab()
                .tabItem {
                    Label("XCFormat", systemImage: "info.circle")
                }

            EngineTab(
                title: "SwiftFormat",
                detail: "Formats Swift code with the bundled SwiftFormat engine.",
                systemImage: "swift",
                iconVerticalOffset: -1,
                executable: SwiftFormat.self
            )
            .tabItem {
                Label("SwiftFormat", systemImage: "swift")
            }

            EngineTab(
                title: "Uncrustify",
                detail: "Formats C-like languages with the bundled Uncrustify engine.",
                systemImage: "curlybraces",
                iconVerticalOffset: 0,
                executable: Uncrustify.self
            )
            .tabItem {
                Label("Uncrustify", systemImage: "curlybraces")
            }
        }
        .frame(width: Self.windowSize.width, height: Self.windowSize.height)
    }
}

private struct XCFormatTab: View {
    var body: some View {
        Form {
            Section("Get Started") {
                VStack(spacing: 0) {
                    SetupStep(
                        number: 1,
                        title: "Enable the extension",
                        detail: "Open General → Login Items & Extensions. Under Extensions, click the info button next to Xcode Source Editor, turn on XCFormat, then click Done.",
                        actionTitle: "Open System Settings",
                        action: openExtensionSettings
                    )

                    Divider()
                        .padding(.leading, 38)

                    SetupStep(
                        number: 2,
                        title: "Relaunch Xcode",
                        detail: "Quit Xcode if it is open, then open it again so it can load the extension."
                    )

                    Divider()
                        .padding(.leading, 38)

                    SetupStep(
                        number: 3,
                        title: "Format your code",
                        detail: "Open a source file, then choose a command from the Editor menu.",
                        commands: [
                            "Format Active File",
                            "Format Selected Lines",
                        ]
                    )
                }
            }
        }
        .formStyle(.grouped)
    }

    private func openExtensionSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}

private struct SetupStep: View {
    let number: Int
    let title: String
    let detail: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    var commands: [String] = []

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number.formatted())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(.tint, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)

                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let actionTitle, let action {
                    HStack {
                        Button(action: action) {
                            Label(actionTitle, systemImage: "gearshape")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)

                        Spacer()
                    }
                    .padding(.top, 2)
                }

                if !commands.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(commands, id: \.self) { command in
                            MenuPath(command: command)
                        }
                    }
                    .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MenuPath: View {
    let command: String

    var body: some View {
        HStack(spacing: 5) {
            Text("Editor")
            Image(systemName: "chevron.right")
            Text("XCFormat")
            Image(systemName: "chevron.right")
            Text(command)
                .foregroundStyle(.primary)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Editor, XCFormat, \(command)")
    }
}

private struct EngineTab: View {
    let title: String
    let detail: String
    let systemImage: String
    let iconVerticalOffset: CGFloat
    let executable: Executable.Type

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .center) {
                        HStack(alignment: .center, spacing: 8) {
                            Image(systemName: systemImage)
                                .font(.headline)
                                .frame(width: 18, height: 18, alignment: .center)
                                .offset(y: iconVerticalOffset)

                            Text(title)
                                .font(.headline)
                        }

                        Spacer()

                        Button(action: openWebsite) {
                            HStack(spacing: 5) {
                                Image("GitHubMark")
                                    .resizable()
                                    .renderingMode(.template)
                                    .scaledToFit()
                                    .frame(width: 13, height: 13)

                                Text("GitHub")
                            }
                        }
                    }
                    .frame(minHeight: 28, alignment: .center)

                    Text(detail)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                LabeledContent("Config") {
                    HStack(spacing: 8) {
                        Button("Show in Finder", action: showConfigInFinder)
                        Button("Reset to Default", action: executable.resetConfigToDefault)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .scrollDisabled(true)
    }

    private func showConfigInFinder() {
        if let path = executable.userConfigPath(createDirectoryIfAbsent: true) {
            NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
        }
    }

    private func openWebsite() {
        if let url = executable.websiteURL {
            NSWorkspace.shared.open(url)
        }
    }
}
