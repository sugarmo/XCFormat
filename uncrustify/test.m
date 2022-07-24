#import <os/lock.h>
#import "YJHeap.h"
#import "YJBufferError.h"
#import "YJRetainedBuffer.h"

typedef NS_OPTIONS(NSUInteger, YJFileLoggerOptions) {
    YJFileLoggerOptionPrint = 1 << 0,
    YJFileLoggerOptionWait  = 1 << 1,
};

typedef NS_ENUM(NSInteger, DisplayMode) {
    // DisplayMode256Colors NS_SWIFT_NAME(with256Colors),
    DisplayModeThousandsOfColors,
    DisplayModeMillionsOfColors,
};

typedef NS_ENUM(NSUInteger, RSSwizzleMode) {
    /// RSSwizzle always does swizzling.
    RSSwizzleModeAlways = 0,
    /// RSSwizzle does not do swizzling if the same class has been swizzled earlier with the same key.
    RSSwizzleModeOncePerClass = 1,
    /// RSSwizzle does not do swizzling if the same class or one of its superclasses have been swizzled earlier with the same key.
    /// @note There is no guarantee that your implementation will be called only once per method call. If the order of swizzling is: first inherited class, second superclass, then both swizzlings will be done and the new implementation will be called twice.
    RSSwizzleModeOncePerClassAndSuperclasses = 2
};

typedef NS_ERROR_ENUM (YJFoundationErrorDomain, YJFoundationError) {
    YJFoundationErrorUnkown = 92501,
    YJFoundationErrorExceptionThrow,
    YJFoundationErrorAllocFailed,
};

#define UI_APPEARANCE_SELECTOR __attribute__((annotate("ui_appearance_selector")))

NSString *SKFuelKindToString(SKFuelKind kind) NS_SWIFT_NAME(getter:SKFuelKind.description(self:));

NSString *SKFuelKindToString(SKFuelKind kind) NS_SWIFT_NAME(SKFuelKind.string(from:));

NSString *SKFuelKindToArg2(SKFuelKind kind, SKFuelKind kind2) NS_SWIFT_NAME(SKFuelKind.string(self:one:))  API_UNAVAILABLE(watchOS,tvos);

NSString *SKFuelKindToArg3(SKFuelKind kind, SKFuelKind kind2, SKFuelKind kind3) NS_SWIFT_NAME(SKFuelKind.string(self:one:two:))  API_AVAILABLE(ios(11.0),tvos(11.0));

#pragma mark - Relative Dates

#define keypath(...) \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Warc-repeated-use-of-weak\"") \
    (NO).boolValue ? ((NSString * _Nonnull)nil) : ((NSString * _Nonnull)@(cStringKeypath(__VA_ARGS__))) \
    _Pragma("clang diagnostic pop") \

#pragma clang diagnostic push   
#pragma clang diagnostic ignored "-Wincompatible-pointer-types"  
   //  
#pragma clang diagnostic pop

NS_SWIFT_NAME(Sandwich.Preferences)
@interface YJFileLogger : NSObject

@property (nonatomic, nullable) NSString *description NS_SWIFT_NAME(desc);

@property (nonatomic, nullable) BOOL isOn NS_SWIFT_NAME(on);

/// \returns \c YES if saved; \c NO with non-nil \c *error if failed to save;
///          \c NO with nil \c *error` if nothing needed to be saved.
- (BOOL)saveToURL:(NSURL *)url error:(NSError **)error NS_SWIFT_NOTHROW DEPRECATED_ATTRIBUTE;

/// @param[out] wasDirty If provided, set to \c YES if the file needed to be
///   saved or \c NO if there weren’t any changes to save.
- (BOOL)saveToURL:(NSURL *)url wasDirty:(nullable BOOL *)wasDirty error:(NSError **)error;

- (void)beginIgnoringInteractionEvents API_DEPRECATED("Use UIView's userInteractionEnabled property instead", ios(2.0, 13.0)) NS_EXTENSION_UNAVAILABLE_IOS("");               // nested. set should be set during animations & transitions to ignore touch and other events

@property(nonatomic, readonly, getter=isIgnoringInteractionEvents) BOOL ignoringInteractionEvents API_DEPRECATED("Use UIView's userInteractionEnabled property instead", ios(2.0, 13.0));                  // returns YES if we are at least one deep in ignoring events

- (UIRemoteNotificationType)enabledRemoteNotificationTypes API_DEPRECATED("Use -[UIApplication isRegisteredForRemoteNotifications] and UserNotifications Framework's -[UNUserNotificationCenter getNotificationSettingsWithCompletionHandler:] to retrieve user-enabled remote notification and user notification settings", ios(3.0, 8.0)) API_UNAVAILABLE(tvos);

- (void)appendFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1, 2);
- (void)appendFormatAndPrint:(NSString *)format, ... NS_FORMAT_FUNCTION(1, 2);

- (nullable CVPixelBufferRef)createCVPixelBufferWithFormat:(OSType)pixelFormat error:(YJErrorPointer)errorPtr CF_RETURNS_RETAINED NS_SWIFT_NAME(makeCVPixelBuffer(format:));

- (YJBitmapFormat *)rgbvFormat:(YJColorSpace *)defaultColorSpace NS_SWIFT_NAME(rgbvFormat(defaultColorSpace:));

- (instancetype)initWithName:(NSString *)name NS_DESIGNATED_INITIALIZER NS_SWIFT_NAME(init(_:));

+ (YJTimeLogger *)loggerWithName:(NSString *)name NS_SWIFT_UNAVAILABLE("Use the designated initializer.");

@end

@implementation YJFileLogger

- (void)enumerateFreePageRanges4:(NS_NOESCAPE dispatch_block_t)callback {
}

- (void)enumerateFreePageRanges2:(YJBuffer ( ^)())callback {
}

- (void)enumerateFreePageRanges3:(NSString *(^)(NSRange range, BOOL *stop))callback {
}

- (void)enumerateFreePageRanges3:(NSString *(^)(NSRange range, BOOL *stop))callback {
}

- (void)enumerateFreePageRanges:(void (^)(NSRange range, BOOL *stop))callback {
}

- (void)enumerateFreePageRanges2:(YJBuffer (NS_NOESCAPE ^)())callback {
}

- (void)enumerateFreePageRanges3:(NSString *(NS_NOESCAPE ^)(NSRange range, BOOL *stop))callback {
}

- (void)enumerateFreePageRanges:(void (NS_NOESCAPE ^)(NSRange range, BOOL *stop))callback {
    __block BOOL ourStop = NO;
    __block NSUInteger startIndex = 0;

    [_usedPageRanges enumerateRangesUsingBlock:^(NSRange range, BOOL *_Nonnull stop) {
        NSUInteger length = range.location - startIndex;

        if (length > 0) {
            callback(NSMakeRange(startIndex, length), &ourStop);
        }

        startIndex = NSMaxRange(range);
        *stop = ourStop;
    }];

    if (ourStop) {
        return;
    }

    if (startIndex < _totalPageCount) {
        callback(NSMakeRange(startIndex, _totalPageCount - startIndex), &ourStop);
    }
}

- (NSRange)newRangeWithPageCount:(NSInteger)pageCount error:(YJErrorPointer)errorPtr {
    __block NSRange newRange = NSRangeNotFound;

    [self enumerateFreePageRanges:^(NSRange range, BOOL *stop) {
        if (range.length >= pageCount) {
//            newBlock = [YJHeapBlock blockWithRange:NSMakeRange(range.location, pageCount)];
            newRange = NSMakeRange(range.location, pageCount);
            *stop = YES;
        }
    }];

    if (!NSEqualRanges(newRange, NSRangeNotFound)) {
        [_usedPageRanges addIndexesInRange:newRange];
        _usedPageCount += newRange.length;
    } else if (errorPtr != nil) {
        *errorPtr = YJErrorMake(YJBufferErrorDomain, YJBufferErrorHeapNoEnoughFreeSpace);
    }

    return newRange;
}

- (void)freeUsedRange:(NSRange)range {
    [_usedPageRanges removeIndexesInRange:range];
    _usedPageCount -= MIN(range.length, _usedPageCount);
}

@end

@interface NSData (YJExifAdditions)

@property (nonatomic, readonly) YJExif *yj_exif NS_SWIFT_NAME(exif);

@end