//
//  SugarFormatterCommand.m
//  SugarFormatter
//
//  Created by Steven Mok on 16/10/13.
//  Copyright © 2016年 ZAKER. All rights reserved.
//

#import "SugarFormatterCommand.h"
#import <AppKit/AppKit.h>

#define FormatActiveFile   @"FormatActiveFile"
#define FormatSelctedLines @"FormatSelctedLines"

@implementation SugarFormatterCommand

- (NSString *)uncrustifyPath
{
      static NSString *uncrustifyPath;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        uncrustifyPath = [[NSBundle mainBundle] pathForResource:@"uncrustify" ofType:nil];
    });
    return uncrustifyPath;
}

- (NSString *)uncrustifyConfigPath
{
    static NSString *uncrustifyConfigPath;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        uncrustifyConfigPath = [[NSBundle mainBundle] pathForResource:@"uncrustify" ofType:@"cfg"];
    });
    return uncrustifyConfigPath;
}

- (NSArray<NSString *> *)convertStringToLines:(NSString *)string
{
    if (!string) {
        return nil;
    }
    NSMutableArray<NSString *> *result = [[NSMutableArray alloc] init];
    [result setArray:[string componentsSeparatedByString:@"\n"]];
    if ([[result lastObject] isEqualToString:@""]) {
        [result removeLastObject];
    }
    return result;
}

- (void)performCommandWithInvocation:(XCSourceEditorCommandInvocation *)invocation completionHandler:(void (^)(NSError * _Nullable nilOrError))completionHandler
{
    NSMutableArray *args = [NSMutableArray array];

    NSString *uti = invocation.buffer.contentUTI;

    BOOL isObjectiveCFile = ([[NSWorkspace sharedWorkspace] type:uti conformsToType:(NSString *)kUTTypeObjectiveCSource]
                             || [[NSWorkspace sharedWorkspace] type:uti conformsToType:(NSString *)kUTTypeCHeader]);

    if (isObjectiveCFile) {
        [args addObjectsFromArray:@[@"-l", @"OC", @"-q"]];
    }

    BOOL isFragmented = NO;
    if ([invocation.commandIdentifier hasSuffix:FormatSelctedLines]) {
        isFragmented = YES;
    }

    if (isFragmented) {
        [args addObject:@"--frag"];
    }

    [args addObjectsFromArray:@[@"-c", [self uncrustifyConfigPath]]];

    NSPipe *errorPipe = NSPipe.pipe;
    NSPipe *outputPipe = NSPipe.pipe;
    NSPipe *inputPie = NSPipe.pipe;

    NSRange selectedLineRange = NSMakeRange(NSNotFound, 0);
    if (isFragmented) {
        XCSourceTextRange *selectedTextRange = invocation.buffer.selections.firstObject;
        selectedLineRange = NSMakeRange(selectedTextRange.start.line, selectedTextRange.end.line - selectedTextRange.start.line + 1);
        NSArray *selectedLines = [invocation.buffer.lines subarrayWithRange:selectedLineRange];
        NSString *selectedString = [selectedLines componentsJoinedByString:@""];
        [inputPie.fileHandleForWriting writeData:[selectedString dataUsingEncoding:NSUTF8StringEncoding]];
    } else {
        [inputPie.fileHandleForWriting writeData:[invocation.buffer.completeBuffer dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [inputPie.fileHandleForWriting closeFile];

    NSTask *task = [[NSTask alloc] init];
    task.standardError = errorPipe;
    task.standardOutput = outputPipe;
    task.standardInput = inputPie;
    task.launchPath = [self uncrustifyPath];
    task.arguments = args;

    [task launch];
    [task waitUntilExit];

    int status = [task terminationStatus];

    NSError *error = nil;

    if (status == 0) {
        NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
        if (outputData) {
            NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
            if (selectedLineRange.location != NSNotFound) {
                NSArray *outputLines = [self convertStringToLines:outputString];
                if (outputLines) {
                    [invocation.buffer.lines replaceObjectsInRange:selectedLineRange withObjectsFromArray:outputLines];
                } else {
                    error = [NSError errorWithDomain:@"com.sugarmo.SugarBox.SugarFormatter" code:201 userInfo:@{NSLocalizedDescriptionKey : @"Output lines convert failed."}];
                }
            } else {
                XCSourceTextRange *preSelection = invocation.buffer.selections.firstObject.copy;
                invocation.buffer.completeBuffer = outputString;
                [invocation.buffer.selections setArray:@[preSelection]];
            }
        } else {
            error = [NSError errorWithDomain:@"com.sugarmo.SugarBox.SugarFormatter" code:101 userInfo:@{NSLocalizedDescriptionKey : @"Uncrustify error — output data is empty."}];
        }
    } else {
        NSData *errorData = [[errorPipe fileHandleForReading] readDataToEndOfFile];
        if (errorData) {
            NSString *errorString = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];
            if (errorString) {
                error = [NSError errorWithDomain:@"com.sugarmo.SugarBox.SugarFormatter" code:202 userInfo:@{NSLocalizedDescriptionKey : errorString}];
            }
        } else {
            NSString *errorString = [NSString stringWithFormat:@"Uncrustify error — exit code %d", status];
            error = [NSError errorWithDomain:@"com.sugarmo.SugarBox.SugarFormatter" code:102 userInfo:@{NSLocalizedDescriptionKey : errorString}];
        }
    }

    completionHandler(error);
}

@end
