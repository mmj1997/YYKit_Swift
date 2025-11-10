//
//  NSObject+YYAddForARC.m
//  YYKit <https://github.com/ibireme/YYKit>
//
//  Created by ibireme on 13/12/15.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//
//
//  NSObject+YYAddForARC.m (ARC Compatible Version)
//  YYKit ARC Safe Edition
//

#import "NSObject+YYAddForARC.h"

@interface NSObject_YYAddForARC : NSObject @end
@implementation NSObject_YYAddForARC @end

@implementation NSObject (YYAddForARC)

// ARC 模式下 retain/release/autorelease 均由编译器自动管理，
// 这些方法仅作为兼容旧代码的空壳占位实现，方便 SwiftPM 编译。

- (instancetype)arcDebugRetain {
    return self;
}

- (oneway void)arcDebugRelease {
    // no-op
}

- (instancetype)arcDebugAutorelease {
    return self;
}

- (NSUInteger)arcDebugRetainCount {
    // ARC 下 retainCount 无法保证正确值，返回 1 以避免误导
    return 1;
}

@end
//#import "NSObject+YYAddForARC.h"
//
//@interface NSObject_YYAddForARC : NSObject @end
//@implementation NSObject_YYAddForARC @end
//
//#if __has_feature(objc_arc)
//#error This file must be compiled without ARC. Specify the -fno-objc-arc flag to this file.
//#endif
//
//
//@implementation NSObject (YYAddForARC)
//
//- (instancetype)arcDebugRetain {
//    return [self retain];
//}
//
//- (oneway void)arcDebugRelease {
//    [self release];
//}
//
//- (instancetype)arcDebugAutorelease {
//    return [self autorelease];
//}
//
//- (NSUInteger)arcDebugRetainCount {
//    return [self retainCount];
//}
//
//@end
