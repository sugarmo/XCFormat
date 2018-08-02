//
//  XCFTask.swift
//  XCFormat
//
//  Created by Steven Mok on 2018/8/1.
//  Copyright © 2018年 sugarmo. All rights reserved.
//

import Foundation
import ObjectiveC.runtime

private var taskAssitantTypeKey: Void?

extension Process {
    enum OutputType {
        case none
        case whenFinished
        case inProgess
    }

    typealias OutputBlock = (_ output: String) -> Void
    typealias TerminateBlock = (_ terminationStatus: Int32) -> Void

    func standardInputHandle() -> FileHandle? {
        return handleFor(object: standardInput, write: false)
    }

    func standardOutputHandle() -> FileHandle? {
        return handleFor(object: standardOutput, write: false)
    }

    func standardErrorHandle() -> FileHandle? {
        return handleFor(object: standardError, write: false)
    }

    private func handleFor(object: Any?, write: Bool) -> FileHandle? {
        if let fileHandle = object as? FileHandle {
            return fileHandle
        } else if let pipe = object as? Pipe {
            return write ? pipe.fileHandleForWriting : pipe.fileHandleForReading
        } else {
            return nil
        }
    }

    func addTerminateBlock(_ block: @escaping TerminateBlock) {
        self.assistant.terminateBlocks.append(block)
    }

    var terminateBlocks: [TerminateBlock] {
        get {
            return assistant.terminateBlocks
        }
        set {
            assistant.terminateBlocks = newValue
        }
    }

    var outputBlock: OutputBlock? {
        get {
            return assistant.outputBlock
        }
        set {
            assistant.outputBlock = newValue
        }
    }

    private var assistant: TaskAssistant {
        get {
            if let assist = objc_getAssociatedObject(self, &taskAssitantTypeKey) as? TaskAssistant {
                return assist
            }

            let newAssit = TaskAssistant(self)
            self.assistant = newAssit
            return newAssit
        }
        set {
            objc_setAssociatedObject(self, &taskAssitantTypeKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    func launch(with outputType: OutputType) {
        switch outputType {
        case .inProgess:
            standardOutputHandle()?.readInBackgroundAndNotify()
        case .whenFinished:
            standardOutputHandle()?.readToEndOfFileInBackgroundAndNotify()
        default:
            break
        }

        launch()
    }
}

private class TaskAssistant: NSObject {
    weak var task: Process?
    var outputBlock: Process.OutputBlock?
    var terminateBlocks: [Process.TerminateBlock] = []

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    init(_ task: Process) {
        self.task = task
        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(taskDidTerminate(_:)), name: Process.didTerminateNotification, object: task)

        if let stdoutHandle = task.standardOutputHandle() {
            NotificationCenter.default.addObserver(self, selector: #selector(stdoutNotifyInProcess(_:)), name: FileHandle.readCompletionNotification, object: stdoutHandle)

            NotificationCenter.default.addObserver(self, selector: #selector(stdoutNotify(_:)), name: .NSFileHandleReadToEndOfFileCompletion, object: stdoutHandle)
        }
    }

    func noticeTerminate() {
        if let terminationStatus = self.task?.terminationStatus {
            DispatchQueue.main.async {
                if self.terminateBlocks.count > 0 {
                    for block in self.terminateBlocks {
                        block(terminationStatus)
                    }
                }
            }
        }
    }

    func noticeOutput(_ output: String) {
        DispatchQueue.main.async {
            self.outputBlock?(output)
        }
    }

    @objc func taskDidTerminate(_ notification: Notification) {
        noticeTerminate()
    }

    @objc func stdoutNotify(_ notification: Notification) {
        if let data = notification.userInfo?[NSFileHandleNotificationDataItem] as? Data {
            if let string = String(data: data, encoding: .utf8) {
                noticeOutput(string)
            }
        }
    }

    @objc func stdoutNotifyInProcess(_ notification: Notification) {
        if let data = notification.userInfo?[NSFileHandleNotificationDataItem] as? Data {
            if let string = String(data: data, encoding: .utf8) {
                noticeOutput(string)
            }

            if let fileHandle = notification.object as? FileHandle {
                fileHandle.readInBackgroundAndNotify()
            }
        }
    }
}
