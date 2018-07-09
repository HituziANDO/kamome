//
// Created by Masaki Ando on 2018/07/06.
// Copyright (c) 2018 Hituzi Ando. All rights reserved.
//

#import "KMMException.h"

@implementation KMMException

static NSString *const kExceptionName = @"KMMException";

+ (instancetype)exceptionWithReason:(NSString *)reason userInfo:(NSDictionary *)userInfo {
    return (KMMException *) [self exceptionWithName:kExceptionName reason:reason userInfo:userInfo];
}

@end
