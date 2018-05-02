//
//  SGBConstant.h
//  XCFormat
//
//  Created by Steven Mok on 16/10/18.
//  Copyright © 2016年 sugarmo. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const SGBErrorDomain;

enum {
    SGBNotAnError = -1
};

typedef void (^SGBCommandCompletion)(NSError *nilOrError);

@interface SGBConstant : NSObject

@end
