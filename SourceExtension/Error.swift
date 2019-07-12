//
//  Error.swift
//  SourceExtension
//
//  Created by Steven Mok on 2019/7/12.
//  Copyright © 2019 sugarmo. All rights reserved.
//

import Cocoa

enum FormatterError: Error {
    case failure(reason: String)
    case missingFile
}
