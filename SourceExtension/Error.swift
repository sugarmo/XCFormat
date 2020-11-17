//
//  Error.swift
//  SourceExtension
//
//  Created by Steven Mok on 2019/7/12.
//  Copyright © 2019 sugarmo. All rights reserved.
//

import Cocoa
import OSLog

enum FormatterError: Error, LocalizedError, CustomNSError {
    case failure(reason: String)
    case execError(print: String)
    case missingFile

    var localizedDescription: String {
        switch self {
        case let .failure(reason):
            return reason
        case let .execError(print):
            os_log(.error, log: .default, "[XCFormat] exec error: %{public}@", print)
            return "Exec error, please check the log in Console."
        case .missingFile:
            return "Missing File"
        }
    }

    var errorUserInfo: [String: Any] {
        return [NSLocalizedDescriptionKey: localizedDescription]
    }
}
