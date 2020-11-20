//
//  FormatterCommand.swift
//  SourceExtension
//
//  Created by Steven Mok on 2018/8/2.
//  Copyright © 2018年 sugarmo. All rights reserved.
//

import Cocoa
import XcodeKit

enum FormatAction: String {
    case formatActiveFile = "FormatActiveFile"
    case formatSelctedLines = "FormatSelctedLines"
}

class FormatterCommand: NSObject, XCSourceEditorCommand {
    private var completion: CommandCompletion?
    private var task: Process?
    private var temporaryFolderURL: URL?

    private func convertStringToLines(_ string: String) -> [String] {
        let comps = string.components(separatedBy: "\n")
        var result = comps
        if result.last == "" {
            result.removeLast()
        }
        return result
    }

    private func cancel() {
        task?.terminate()
        cleanup()
    }

    private func createTemporayFolder() throws -> URL? {
        let rootURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let temporaryFolderURL = rootURL.appendingPathComponent(UUID().uuidString, isDirectory: true)

        try FileManager.default.createDirectory(at: temporaryFolderURL, withIntermediateDirectories: true, attributes: nil)

        return temporaryFolderURL
    }

    private func cleanup() {
        if let url = temporaryFolderURL {
            try? FileManager.default.removeItem(at: url)
        }
        temporaryFolderURL = nil
        completion = nil
        task = nil
    }

    private func didSucceedPerformCommand() {
        completion?(nil)
        cleanup()
    }

    private func didFailedPerformCommand(_ error: Error) {
        completion?(error)
        cleanup()
    }

    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) {
        do {
            try temporaryFolderURL = createTemporayFolder()

            invocation.cancellationHandler = {
                self.cancel()
            }
            completion = completionHandler

            let uti = invocation.buffer.contentUTI

            if SwiftFormat.supportedUTIs.contains(uti) {
                task = try makeTask(with: SwiftFormat.self, invocation: invocation)
            } else {
                task = try makeTask(with: Uncrustify.self, invocation: invocation)
            }

            task?.launch(with: .none)

            while task != nil {
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
            }
        } catch let error {
            didFailedPerformCommand(error)
            return
        }
    }

    private func taskDidTerminated(_ terminationStatus: Int32,
                                   invocation: XCSourceEditorCommandInvocation,
                                   selectedLineRange: NSRange,
                                   sourceFileURL: URL) {
        do {
            if terminationStatus == 0 {
                let formattedSubstring = try String(contentsOf: sourceFileURL, encoding: .utf8)

                if selectedLineRange.location != NSNotFound {
                    let outputLines = convertStringToLines(formattedSubstring)
                    if outputLines.count > 0 {
                        invocation.buffer.lines.replaceObjects(in: selectedLineRange, withObjectsFrom: outputLines)
                        didSucceedPerformCommand()
                        return
                    } else {
                        throw FormatterError.failure(reason: "Output lines convert failed.")
                    }
                } else {
                    if let preSelection = invocation.buffer.selections.firstObject {
                        invocation.buffer.completeBuffer = formattedSubstring
                        invocation.buffer.selections.setArray([preSelection])
                    }
                    didSucceedPerformCommand()
                    return
                }
            } else {
                if let errorData = task?.standardErrorHandle()?.readDataToEndOfFile(), let print = String(data: errorData, encoding: .utf8) {
                    throw FormatterError.execError(print: print)
                } else {
                    throw FormatterError.failure(reason: "Uncrustify error — exit code \(terminationStatus)")
                }
            }
        } catch let error {
            didFailedPerformCommand(error)
            return
        }
    }

    private func makePathExtension(uti: String) -> String {
        if let ext = UTTypeCopyPreferredTagWithClass(uti as CFString, kUTTagClassFilenameExtension) {
            return ext.takeRetainedValue() as String
        }
        return ""
    }

    private func makeTask(with execType: Executable.Type, invocation: XCSourceEditorCommandInvocation) throws -> Process {
        let uti = invocation.buffer.contentUTI
        let isFragmented = invocation.commandIdentifier.hasSuffix(FormatAction.formatSelctedLines.rawValue)
        let pathExtension = execType.makePathExtension(uti: uti) ?? makePathExtension(uti: uti)
        let sourceFileName = "sourcecode".bridged.appendingPathExtension(pathExtension)!
        let sourceFileURL = temporaryFolderURL!.appendingPathComponent(sourceFileName, isDirectory: false)

        var selectedLineRange = NSMakeRange(NSNotFound, 0)
        if isFragmented {
            let selectedTextRange = invocation.buffer.selections.firstObject as! XCSourceTextRange
            selectedLineRange = NSMakeRange(selectedTextRange.start.line, selectedTextRange.end.line - selectedTextRange.start.line + 1)
            let selectedLines = invocation.buffer.lines.subarray(with: selectedLineRange) as NSArray
            let selectedString = selectedLines.componentsJoined(by: "")
            try selectedString.write(to: sourceFileURL, atomically: true, encoding: .utf8)
        } else {
            try invocation.buffer.completeBuffer.write(to: sourceFileURL, atomically: true, encoding: .utf8)
        }

        let args = try execType.makeTaskArgs(uti: uti, isFragmented: isFragmented, sourceFile: sourceFileURL.path)

        let task = Process()
        task.standardError = Pipe()
        task.launchPath = execType.execPath
        task.arguments = args

        task.addTerminateBlock { (terminationStatus: Int32) in
            self.taskDidTerminated(terminationStatus, invocation: invocation, selectedLineRange: selectedLineRange, sourceFileURL: sourceFileURL)
        }

        return task
    }
}
