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
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Xcode Source Editor Extension")
                        .font(.headline)

                    Text("Enable it in System Settings > Extensions > Xcode Source Editor. After that, use Editor > XCFormat in Xcode to format the current file or selected text.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .formStyle(.grouped)
        .scrollDisabled(true)
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
