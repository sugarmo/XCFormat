//
//  Error.swift
//  SourceExtension
//
//  Created by Steven Mok on 2019/7/12.
//  Copyright © 2019 sugarmo. All rights reserved.
//

import Cocoa

enum FormatterError: Error, LocalizedError, CustomNSError {
    case failure(reason: String)
    case execError(print: String)
    case missingFile

    var localizedDescription: String {
        switch self {
        case let .failure(reason):
            return reason
        case let .execError(print):
            if let regexp = try? NSRegularExpression(pattern: #"error:\s*(.+):"#, options: .caseInsensitive) {
                if let match = regexp.firstMatch(in: print, options: [], range: NSRange(location: 0, length: print.count)) {
                    if let range = Range(match.range(at: 1), in: print) {
                        return String(print[range])
                    }
                }
            }
            return print
        case .missingFile:
            return "Missing File"
        }
    }

    var errorUserInfo: [String: Any] {
        return [NSLocalizedDescriptionKey: localizedDescription]
    }
}
