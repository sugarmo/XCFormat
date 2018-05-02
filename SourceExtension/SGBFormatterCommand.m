//
//  SGBFormatterCommand.m
//  SourceExtension
//
//  Created by Steven Mok on 16/10/13.
//  Copyright © 2016年 ZAKER. All rights reserved.
//

#import "SGBFormatterCommand.h"
#import "PRCTask.h"
#import "SGBConstant.h"
#import <AppKit/AppKit.h>

#define FormatActiveFile   @"FormatActiveFile"
#define FormatSelctedLines @"FormatSelctedLines"

NSString *const SGBFormatterErrorDomain = @"com.sugarmo.XCFormat.SourceExtension";

enum {
    SGBFormatterFailureError,
};

@interface SGBFormatterCommand ()

@property (nonatomic, copy) SGBCommandCompletion completion;

@property (nonatomic, strong) NSTask *task;

@property (nonatomic, strong) NSURL *temporaryFolderURL;

@property (nonatomic, strong) NSError *lastError;

@end

@implementation SGBFormatterCommand

- (NSError *)errorWithReason:(NSString *)reason
{
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : reason};
    return [NSError errorWithDomain:SGBFormatterErrorDomain code:SGBFormatterFailureError userInfo:userInfo];
}

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

- (void)cancel
{
    [self.task terminate];
    [self cleanUp];
}

- (NSURL *)createTemporayFolder
{
    NSURL *temporaryFolderURL = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES] URLByAppendingPathComponent:[[NSUUID UUID] UUIDString] isDirectory:YES];

    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:temporaryFolderURL.path withIntermediateDirectories:YES attributes:nil error:&error];

    if (error) {
        self.lastError = error;
        return nil;
    } else {
        return temporaryFolderURL;
    }
}

- (void)cleanUp
{
    // we don't care about the error of removing temp files
    if (self.temporaryFolderURL) {
        [[NSFileManager defaultManager] removeItemAtURL:self.temporaryFolderURL error:NULL];
    }
    self.temporaryFolderURL = nil;
    self.completion = nil;
    self.lastError = nil;
    self.task = nil;
}

- (void)didSucceedPerformCommand
{
    if (self.completion) {
        self.completion(nil);
    }
    [self cleanUp];
}

- (void)didFailedPerformCommand
{
    if (self.completion) {
        self.completion(self.lastError);
    }
    [self cleanUp];
}

- (void)performCommandWithInvocation:(XCSourceEditorCommandInvocation *)invocation completionHandler:(void (^)(NSError * _Nullable nilOrError))completionHandler
{
    self.temporaryFolderURL = [self createTemporayFolder];

    if (self.lastError) {
        [self didFailedPerformCommand];
        return;
    }

    [invocation setCancellationHandler:^{
        [self cancel];
    }];
    self.completion = completionHandler;

    self.task = [self makeTaskWithInvocation:invocation];

    if (self.lastError) {
        [self didFailedPerformCommand];
        return;
    }

    [self.task prc_launchWithOutputType:PRCTaskOutputNone];

    while (self.task) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
}

- (void)taskDidTerminated:(int)terminationStatus invocation:(XCSourceEditorCommandInvocation *)invocation selectedLineRange:(NSRange)selectedLineRange sourceFileURL:(NSURL *)sourceFileURL
{
    if (terminationStatus == 0) {
        NSError *error = nil;
        NSString *formattedSubstring = [NSString stringWithContentsOfURL:sourceFileURL encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            self.lastError = error;
            [self didFailedPerformCommand];
            return;
        }

        if (formattedSubstring) {
            if (selectedLineRange.location != NSNotFound) {
                NSArray *outputLines = [self convertStringToLines:formattedSubstring];
                if (outputLines) {
                    [invocation.buffer.lines replaceObjectsInRange:selectedLineRange withObjectsFromArray:outputLines];
                    [self didSucceedPerformCommand];
                    return;
                } else {
                    self.lastError = [self errorWithReason:@"Output lines convert failed."];
                    [self didFailedPerformCommand];
                    return;
                }
            } else {
                XCSourceTextRange *preSelection = invocation.buffer.selections.firstObject.copy;
                invocation.buffer.completeBuffer = formattedSubstring;
                [invocation.buffer.selections setArray:@[preSelection]];
                [self didSucceedPerformCommand];
                return;
            }
        } else {
            self.lastError = [self errorWithReason:@"Uncrustify error — output data is empty."];
            [self didFailedPerformCommand];
            return;
        }
    } else {
        NSData *errorData = [[self.task prc_standardErrorHandle] readDataToEndOfFile];
        if (errorData) {
            self.lastError = [self errorWithReason:[[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding]];
            [self didFailedPerformCommand];
            return;
        } else {
            self.lastError = [self errorWithReason:[NSString stringWithFormat:@"Uncrustify error — exit code %d", terminationStatus]];
            [self didFailedPerformCommand];
            return;
        }
    }
}

- (NSTask *)makeTaskWithInvocation:(XCSourceEditorCommandInvocation *)invocation
{
    NSError *error = nil;

    NSMutableArray<NSString *> *args = [NSMutableArray array];

    [args addObject:@"--no-backup"];

    NSString *uti = invocation.buffer.contentUTI;

    BOOL isObjectiveCFile = ([[NSWorkspace sharedWorkspace] type:uti conformsToType:(NSString *)kUTTypeObjectiveCSource]
                             || [[NSWorkspace sharedWorkspace] type:uti conformsToType:(NSString *)kUTTypeCHeader]);

    if (isObjectiveCFile) {
        [args addObjectsFromArray:@[@"-l", @"OC"]];
    }

    BOOL isFragmented = NO;
    if ([invocation.commandIdentifier hasSuffix:FormatSelctedLines]) {
        isFragmented = YES;
    }

    if (isFragmented) {
        [args addObject:@"--frag"];
    }

    [args addObjectsFromArray:@[@"-c", [self uncrustifyConfigPath]]];

    NSURL *sourceFileURL = [self.temporaryFolderURL URLByAppendingPathComponent:@"sourcecode" isDirectory:NO];
    [args addObject:sourceFileURL.path];

    NSPipe *errorPipe = NSPipe.pipe;

    NSRange selectedLineRange = NSMakeRange(NSNotFound, 0);
    if (isFragmented) {
        XCSourceTextRange *selectedTextRange = invocation.buffer.selections.firstObject;
        selectedLineRange = NSMakeRange(selectedTextRange.start.line, selectedTextRange.end.line - selectedTextRange.start.line + 1);
        NSArray *selectedLines = [invocation.buffer.lines subarrayWithRange:selectedLineRange];
        NSString *selectedString = [selectedLines componentsJoinedByString:@""];
        [selectedString writeToURL:sourceFileURL atomically:YES encoding:NSUTF8StringEncoding error:&error];

        if (error) {
            self.lastError = error;
            return nil;
        }
    } else {
        [invocation.buffer.completeBuffer writeToURL:sourceFileURL atomically:YES encoding:NSUTF8StringEncoding error:&error];

        if (error) {
            self.lastError = error;
            return nil;
        }
    }

    NSTask *task = [[NSTask alloc] init];
    task.standardError = errorPipe;
    task.launchPath = [self uncrustifyPath];
    task.arguments = args;

    [task prc_addTerminateBlock:^(int terminationStatus) {
        [self taskDidTerminated:terminationStatus invocation:invocation selectedLineRange:selectedLineRange sourceFileURL:sourceFileURL];
    }];
    
    return task;
}

@end
