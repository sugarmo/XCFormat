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

NSString *const SGMFormatterErrorDomain = @"com.sugarmo.SugarBox.SugarFormatter";

enum {
    SGMFormatterFailureError,
};

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
    NSError *error = nil;
    NSURL *temporaryFolderURL = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES] URLByAppendingPathComponent:[[NSUUID UUID] UUIDString] isDirectory:YES];
    [[NSFileManager defaultManager] createDirectoryAtPath:temporaryFolderURL.path withIntermediateDirectories:YES attributes:nil error:&error];

    if (error) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"Unable to create the temporary folder (`%@`) for Uncrustify. Error: %@.", nil), temporaryFolderURL.path, error.localizedDescription]};
        error = [NSError errorWithDomain:SGMFormatterErrorDomain code:SGMFormatterFailureError userInfo:userInfo];
        completionHandler(error);
        return;
    }

    [self performCommandWithInvocation:invocation temporaryFolderURL:temporaryFolderURL error:&error];

    // not change the error, because we don't care about the error of removing temp files
    [[NSFileManager defaultManager] removeItemAtURL:temporaryFolderURL error:NULL];

    completionHandler(error);
}

- (NSError *)errorWithReason:(NSString *)reason
{
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : reason};
    return [NSError errorWithDomain:SGMFormatterErrorDomain code:SGMFormatterFailureError userInfo:userInfo];
}

- (BOOL)performCommandWithInvocation:(XCSourceEditorCommandInvocation *)invocation temporaryFolderURL:(NSURL *)temporaryFolderURL error:(NSError **)outError
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

    NSURL *sourceFileURL = [temporaryFolderURL URLByAppendingPathComponent:@"sourcecode" isDirectory:NO];
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
            if (outError) {
                *outError = error;
            }
            return NO;
        }
    } else {
        [invocation.buffer.completeBuffer writeToURL:sourceFileURL atomically:YES encoding:NSUTF8StringEncoding error:&error];

        if (error) {
            if (outError) {
                *outError = error;
            }
            return NO;
        }
    }

    NSTask *task = [[NSTask alloc] init];
    task.standardError = errorPipe;
    task.launchPath = [self uncrustifyPath];
    task.arguments = args;

    [task launch];
    [task waitUntilExit];

    int status = [task terminationStatus];

    if (status == 0) {
        NSString *formattedSubstring = [NSString stringWithContentsOfURL:sourceFileURL encoding:NSUTF8StringEncoding error:&error];
        if (formattedSubstring) {
            if (selectedLineRange.location != NSNotFound) {
                NSArray *outputLines = [self convertStringToLines:formattedSubstring];
                if (outputLines) {
                    [invocation.buffer.lines replaceObjectsInRange:selectedLineRange withObjectsFromArray:outputLines];
                    return YES;
                } else {
                    error = [self errorWithReason:@"Output lines convert failed."];
                    if (outError) {
                        *outError = error;
                    }
                }
            } else {
                XCSourceTextRange *preSelection = invocation.buffer.selections.firstObject.copy;
                invocation.buffer.completeBuffer = formattedSubstring;
                [invocation.buffer.selections setArray:@[preSelection]];
                return YES;
            }
        } else {
            error = [self errorWithReason:@"Uncrustify error — output data is empty."];
            if (outError) {
                *outError = error;
            }
        }
    } else {
        NSData *errorData = [[errorPipe fileHandleForReading] readDataToEndOfFile];
        if (errorData) {
            error = [self errorWithReason:[[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding]];
            if (outError) {
                *outError = error;
            }
        } else {
            error = [self errorWithReason:[NSString stringWithFormat:@"Uncrustify error — exit code %d", status]];
            if (outError) {
                *outError = error;
            }
        }
    }
    
    return NO;
}

@end
