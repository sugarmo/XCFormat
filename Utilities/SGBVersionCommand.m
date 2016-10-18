//
//  SGBVersionCommand.m
//  SugarBox
//
//  Created by Steven Mok on 16/10/18.
//  Copyright © 2016年 sugarmo. All rights reserved.
//

#import "SGBVersionCommand.h"
#import "SGBConstant.h"

@implementation SGBVersionCommand

- (void)performCommandWithInvocation:(XCSourceEditorCommandInvocation *)invocation completionHandler:(void (^)(NSError * _Nullable nilOrError))completionHandler
{
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    NSString *text = [NSString stringWithFormat:@"Version is %@", version];
    NSError *error = [NSError errorWithDomain:SGBErrorDomain code:SGBNotAnError userInfo:@{NSLocalizedDescriptionKey: text}];
    completionHandler(error);
}

@end
