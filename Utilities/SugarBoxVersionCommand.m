//
//  SugarBoxVersionCommand.m
//  SugarBox
//
//  Created by Steven Mok on 16/10/18.
//  Copyright © 2016年 sugarmo. All rights reserved.
//

#import "SugarBoxVersionCommand.h"

NSString *const SGMErrorDomain = @"com.sugarmo.SugarBox";

enum {
    SGMNotAnError
};

@implementation SugarBoxVersionCommand

- (void)performCommandWithInvocation:(XCSourceEditorCommandInvocation *)invocation completionHandler:(void (^)(NSError * _Nullable nilOrError))completionHandler
{
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    NSString *text = [NSString stringWithFormat:@"Version is %@", version];
    NSError *error = [NSError errorWithDomain:SGMErrorDomain code:SGMNotAnError userInfo:@{NSLocalizedDescriptionKey: text}];
    completionHandler(error);
}

@end
