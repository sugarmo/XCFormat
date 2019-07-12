//
//  NativeSwiftFormatter.swift
//  SourceExtension
//
//  Created by Steven Mok on 2019/4/25.
//  Copyright © 2019 sugarmo. All rights reserved.
//

import Cocoa

extension String {
    func bridged() -> NSString {
        return self as NSString
    }
}

#if canImport(XcodeKit)
    import XcodeKit

    extension XCSourceTextBuffer {
        var indentationString: String {
            if usesTabsForIndentation {
                let tabCount = indentationWidth / tabWidth
                if tabCount * tabWidth == indentationWidth {
                    return String(repeating: "\t", count: tabCount)
                }
            }
            return String(repeating: " ", count: indentationWidth)
        }
    }
#endif
