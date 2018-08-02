//
//  PRCTask.m
//  Parachute
//
//  Created by Steven Mok on 15/11/2.
//  Copyright © 2015年 ZAKER. All rights reserved.
//

#import "PRCTask.h"
#import <objc/runtime.h>

static char PRCTaskAssitantTypeKey;

@interface PRCTaskAssistant : NSObject

@property (nonatomic, readonly, weak) NSTask *task;

@property (nonatomic, copy) PRCTaskOutputBlock outputBlock;

@property (nonatomic, copy) NSArray<PRCTaskTerminateBlock> *terminateBlocks;

- (instancetype)initWithTask:(NSTask *)task;

@end

@implementation PRCTaskAssistant

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithTask:(NSTask *)task
{
    self = [self init];

    if (self) {
        _task = task;

        if (!_task) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"task is nil" userInfo:nil];
        }

        NSFileHandle *stdoutHandle = [_task prc_standardOutputHandle];

        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

        [notificationCenter addObserver:self selector:@selector(taskDidTerminate:) name:NSTaskDidTerminateNotification object:_task];

        if (stdoutHandle) {
            [notificationCenter addObserver:self selector:@selector(stdoutNotifyInProcess:) name:NSFileHandleReadCompletionNotification object:stdoutHandle];
            [notificationCenter addObserver:self selector:@selector(stdoutNotify:) name:NSFileHandleReadToEndOfFileCompletionNotification object:stdoutHandle];
        }
    }

    return self;
}

- (void)noticeTerminate
{
    int terminationStatus = self.task.terminationStatus;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.terminateBlocks.count > 0) {
            for (PRCTaskTerminateBlock block in self.terminateBlocks) {
                block(terminationStatus);
            }
        }
    });
}

- (void)noticeOutput:(NSString *)output
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.outputBlock) {
            self.outputBlock(output);
        }
    });
}

- (void)taskDidTerminate:(NSNotification *)notification
{
    [self noticeTerminate];
}

- (void)stdoutNotify:(NSNotification *)notification
{
    NSData *data = [[notification userInfo] valueForKey:NSFileHandleNotificationDataItem];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    [self noticeOutput:string];
}

- (void)stdoutNotifyInProcess:(NSNotification *)notification
{
    NSData *data = [[notification userInfo] valueForKey:NSFileHandleNotificationDataItem];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    [self noticeOutput:string];

    [(NSFileHandle *)notification.object readInBackgroundAndNotify];
}

@end

@implementation NSTask (PRCAdditions)

- (NSFileHandle *)prc_handleForObject:(id)object write:(BOOL)write
{
    if ([object isKindOfClass:[NSFileHandle class]]) {
        return object;
    } else if ([object isKindOfClass:[NSPipe class]]) {
        if (write) {
            return [object fileHandleForWriting];
        } else {
            return [object fileHandleForReading];
        }
    } else {
        return nil;
    }
}

- (NSFileHandle *)prc_standardInputHandle
{
    return [self prc_handleForObject:self.standardInput write:YES];
}

- (NSFileHandle *)prc_standardOutputHandle
{
    return [self prc_handleForObject:self.standardOutput write:NO];
}

- (NSFileHandle *)prc_standardErrorHandle
{
    return [self prc_handleForObject:self.standardError write:NO];
}

- (void)prc_launchWithOutputType:(PRCTaskOutputType)outputType
{
    if (outputType == PRCTaskOutputInProgcess) {
        [[self prc_standardOutputHandle] readInBackgroundAndNotify];
    } else if (outputType == PRCTaskOutputWhenFinished) {
        [[self prc_standardOutputHandle] readToEndOfFileInBackgroundAndNotify];
    }

    [self launch];
}

- (PRCTaskAssistant *)prc_assistant
{
    PRCTaskAssistant *assistant = objc_getAssociatedObject(self, &PRCTaskAssitantTypeKey);
    if (!assistant) {
        assistant = [[PRCTaskAssistant alloc] initWithTask:self];
        [self prc_setAssistant:assistant];
    }
    return assistant;
}

- (void)prc_setAssistant:(PRCTaskAssistant *)assistant
{
    objc_setAssociatedObject(self, &PRCTaskAssitantTypeKey, assistant, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)prc_addTerminateBlock:(PRCTaskTerminateBlock)terminateBlock
{
    NSMutableArray<PRCTaskTerminateBlock> *blocks = [NSMutableArray arrayWithArray:[self prc_assistant].terminateBlocks];
    [blocks addObject:[terminateBlock copy]];
    [self prc_setTerminateBlocks:blocks];
}

- (NSArray<PRCTaskTerminateBlock> *)prc_terminateBlocks
{
    return [self prc_assistant].terminateBlocks;
}

- (void)prc_setTerminateBlocks:(NSArray<PRCTaskTerminateBlock> *)terminateBlocks
{
    [self prc_assistant].terminateBlocks = terminateBlocks;
}

- (PRCTaskOutputBlock)prc_outputBlock
{
    return [self prc_assistant].outputBlock;
}

- (void)prc_setOutputBlock:(PRCTaskOutputBlock)outputBlock
{
    [self prc_assistant].outputBlock = outputBlock;
}

@end
