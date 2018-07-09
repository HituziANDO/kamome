//
// Created by Masaki Ando on 2018/07/06.
// Copyright (c) 2018 Hituzi Ando. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KMMException : NSException

+ (instancetype)exceptionWithReason:(nullable NSString *)reason userInfo:(nullable NSDictionary *)userInfo;

@end

NS_ASSUME_NONNULL_END
