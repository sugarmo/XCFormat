//
//  Constants.swift
//  XCFormat
//
//  Created by Steven Mok on 2018/8/2.
//  Copyright © 2018年 sugarmo. All rights reserved.
//

import Foundation

enum AppError: Error {
    case notAnError
}

typealias CommandCompletion = (_ error: Error?) -> Void
