

////
////  NSThread+YYAdd.h
////  YYKit <https://github.com/ibireme/YYKit>
////
////  Created by ibireme on 15/7/3.
////  Copyright (c) 2015 ibireme.
////
////  This source code is licensed under the MIT-style license found in the
////  LICENSE file in the root directory of this source tree.
////
//
//  NSThread+YYAdd.m (ARC Compatible Version)
//  YYKit ARC Safe Edition
//
//  原始代码需要在非 ARC 环境编译
//  现版本已改写为 ARC 可用
//

#import <CoreFoundation/CoreFoundation.h>
#import "NSThread+YYAdd.h"

@interface NSThread_YYAdd : NSObject @end
@implementation NSThread_YYAdd @end

static NSString * const YYNSThreadAutoreleasePoolKey = @"YYNSThreadAutoreleasePoolKey";
static NSString *const YYNSThreadAutoreleasePoolStackKey = @"YYNSThreadAutoreleasePoolStackKey";

#pragma mark - CF Callbacks (ARC Safe)

static const void * PoolStackRetainCallBack(CFAllocatorRef allocator, const void *value) {
    // ARC 会自动管理对象，无需 retain
    return value;
}

static void PoolStackReleaseCallBack(CFAllocatorRef allocator, const void *value) {
    // ARC 模式下不再手动 CFRelease
}

#pragma mark - Autorelease Pool Push/Pop

static inline void YYAutoreleasePoolPush(void) {
    NSMutableDictionary *dic = [NSThread currentThread].threadDictionary;
    NSMutableArray *poolStack = dic[YYNSThreadAutoreleasePoolStackKey];

    if (!poolStack) {
        CFArrayCallBacks callbacks = {
            0
        };
        callbacks.retain = PoolStackRetainCallBack;
        callbacks.release = PoolStackReleaseCallBack;
        // ARC 模式下直接用 __bridge_transfer 来托管 CFArray
        poolStack = (__bridge_transfer NSMutableArray *)CFArrayCreateMutable(NULL, 0, &callbacks);
        dic[YYNSThreadAutoreleasePoolStackKey] = poolStack;
    }

    // 用 @autoreleasepool 替代 NSAutoreleasePool 手动管理
    @autoreleasepool {
        id marker = [NSObject new];
        [poolStack addObject:marker]; // 仅作标记作用
    }
}

static inline void YYAutoreleasePoolPop(void) {
    NSMutableDictionary *dic = [NSThread currentThread].threadDictionary;
    NSMutableArray *poolStack = dic[YYNSThreadAutoreleasePoolStackKey];

    if (poolStack.count > 0) {
        [poolStack removeLastObject];
    }
}

#pragma mark - RunLoop Observer Callback

static void YYRunLoopAutoreleasePoolObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    switch (activity) {
        case kCFRunLoopEntry:
            YYAutoreleasePoolPush();
            break;

        case kCFRunLoopBeforeWaiting:
            YYAutoreleasePoolPop();
            YYAutoreleasePoolPush();
            break;

        case kCFRunLoopExit:
            YYAutoreleasePoolPop();
            break;

        default:
            break;
    }
}

#pragma mark - Setup

static void YYRunLoopAutoreleasePoolSetup(void) {
    CFRunLoopRef runloop = CFRunLoopGetCurrent();

    CFRunLoopObserverRef pushObserver = CFRunLoopObserverCreate(
        NULL,
        kCFRunLoopEntry,
        true,
        INT_MIN,
        YYRunLoopAutoreleasePoolObserverCallBack,
        NULL
        );

    CFRunLoopAddObserver(runloop, pushObserver, kCFRunLoopCommonModes);
    CFRelease(pushObserver);

    CFRunLoopObserverRef popObserver = CFRunLoopObserverCreate(
        NULL,
        kCFRunLoopBeforeWaiting | kCFRunLoopExit,
        true,
        INT_MAX,
        YYRunLoopAutoreleasePoolObserverCallBack,
        NULL
        );
    CFRunLoopAddObserver(runloop, popObserver, kCFRunLoopCommonModes);
    CFRelease(popObserver);
}

#pragma mark - Public API

@implementation NSThread (YYAdd)

+ (void)addAutoreleasePoolToCurrentRunloop {
    if ([NSThread isMainThread]) {
        return;                          // 主线程已有 autorelease pool
    }

    NSThread *thread = [self currentThread];

    if (!thread) {
        return;
    }

    if (thread.threadDictionary[YYNSThreadAutoreleasePoolKey]) {
        return;                                                        // 已添加
    }

    YYRunLoopAutoreleasePoolSetup();
    thread.threadDictionary[YYNSThreadAutoreleasePoolKey] = YYNSThreadAutoreleasePoolKey;
}

@end


//
//#import <CoreFoundation/CoreFoundation.h>
//#import "NSThread+YYAdd.h"
//
//@interface NSThread_YYAdd : NSObject @end
//@implementation NSThread_YYAdd @end
//
//#if __has_feature(objc_arc)
//#error This file must be compiled without ARC. Specify the -fno-objc-arc flag to this file.
//#endif
//
//static NSString *const YYNSThreadAutoleasePoolKey = @"YYNSThreadAutoleasePoolKey";
//static NSString *const YYNSThreadAutoleasePoolStackKey = @"YYNSThreadAutoleasePoolStackKey";
//
//static const void * PoolStackRetainCallBack(CFAllocatorRef allocator, const void *value) {
//    return value;
//}
//
//static void PoolStackReleaseCallBack(CFAllocatorRef allocator, const void *value) {
//    CFRelease((CFTypeRef)value);
//}
//
//static inline void YYAutoreleasePoolPush() {
//    NSMutableDictionary *dic =  [NSThread currentThread].threadDictionary;
//    NSMutableArray *poolStack = dic[YYNSThreadAutoleasePoolStackKey];
//
//    if (!poolStack) {
//        /*
//           do not retain pool on push,
//           but release on pop to avoid memory analyze warning
//         */
//        CFArrayCallBacks callbacks = {
//            0
//        };
//        callbacks.retain = PoolStackRetainCallBack;
//        callbacks.release = PoolStackReleaseCallBack;
//        poolStack = (id)CFArrayCreateMutable(CFAllocatorGetDefault(), 0, &callbacks);
//        dic[YYNSThreadAutoleasePoolStackKey] = poolStack;
//        CFRelease(poolStack);
//    }
//
//    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; // create
//    [poolStack addObject:pool]; // push
//}
//
//static inline void YYAutoreleasePoolPop() {
//    NSMutableDictionary *dic =  [NSThread currentThread].threadDictionary;
//    NSMutableArray *poolStack = dic[YYNSThreadAutoleasePoolStackKey];
//
//    [poolStack removeLastObject]; // pop
//}
//
//static void YYRunLoopAutoreleasePoolObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
//    switch (activity) {
//        case kCFRunLoopEntry: {
//            YYAutoreleasePoolPush();
//        } break;
//
//        case kCFRunLoopBeforeWaiting: {
//            YYAutoreleasePoolPop();
//            YYAutoreleasePoolPush();
//        } break;
//
//        case kCFRunLoopExit: {
//            YYAutoreleasePoolPop();
//        } break;
//
//        default: break;
//    }
//}
//
//static void YYRunloopAutoreleasePoolSetup() {
//    CFRunLoopRef runloop = CFRunLoopGetCurrent();
//
//    CFRunLoopObserverRef pushObserver;
//
//    pushObserver = CFRunLoopObserverCreate(CFAllocatorGetDefault(), kCFRunLoopEntry,
//                                           true,         // repeat
//                                           -0x7FFFFFFF,  // before other observers
//                                           YYRunLoopAutoreleasePoolObserverCallBack, NULL);
//    CFRunLoopAddObserver(runloop, pushObserver, kCFRunLoopCommonModes);
//    CFRelease(pushObserver);
//
//    CFRunLoopObserverRef popObserver;
//    popObserver = CFRunLoopObserverCreate(CFAllocatorGetDefault(), kCFRunLoopBeforeWaiting | kCFRunLoopExit,
//                                          true,        // repeat
//                                          0x7FFFFFFF,  // after other observers
//                                          YYRunLoopAutoreleasePoolObserverCallBack, NULL);
//    CFRunLoopAddObserver(runloop, popObserver, kCFRunLoopCommonModes);
//    CFRelease(popObserver);
//}
//
//@implementation NSThread (YYAdd)
//
//+ (void)addAutoreleasePoolToCurrentRunloop {
//    if ([NSThread isMainThread]) {
//        return;                          // The main thread already has autorelease pool.
//    }
//
//    NSThread *thread = [self currentThread];
//
//    if (!thread) {
//        return;
//    }
//
//    if (thread.threadDictionary[YYNSThreadAutoleasePoolKey]) {
//        return;                                                      // already added
//    }
//
//    YYRunloopAutoreleasePoolSetup();
//    thread.threadDictionary[YYNSThreadAutoleasePoolKey] = YYNSThreadAutoleasePoolKey; // mark the state
//}
//
//@end
