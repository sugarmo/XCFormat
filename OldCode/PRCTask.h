//
//  PRCTask.h
//  Parachute
//
//  Created by Steven Mok on 15/11/2.
//  Copyright © 2015年 ZAKER. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^PRCTaskOutputBlock)(NSString *output);
typedef void (^PRCTaskTerminateBlock)(int terminationStatus);

typedef NS_ENUM (NSInteger, PRCTaskOutputType) {
    PRCTaskOutputNone = 0,
    PRCTaskOutputWhenFinished,
    PRCTaskOutputInProgcess,
};

@interface NSTask (PRCAdditions)

- (NSFileHandle *)prc_standardInputHandle;
- (NSFileHandle *)prc_standardOutputHandle;
- (NSFileHandle *)prc_standardErrorHandle;

- (void)prc_addTerminateBlock:(PRCTaskTerminateBlock)terminateBlock;

- (NSArray<PRCTaskTerminateBlock> *)prc_terminateBlocks;
- (void)prc_setTerminateBlocks:(NSArray<PRCTaskTerminateBlock> *)terminateBlocks;

- (PRCTaskOutputBlock)prc_outputBlock;
- (void)prc_setOutputBlock:(PRCTaskOutputBlock)outputBlock;

/**
 自动根据outputType选择readFile的方法
 */
- (void)prc_launchWithOutputType:(PRCTaskOutputType)outputType;

@end
