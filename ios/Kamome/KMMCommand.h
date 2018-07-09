//
// Created by Masaki Ando on 2018/07/05.
// Copyright (c) 2018 Hituzi Ando. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class KMMCompletion;

@interface KMMCommand : NSObject

@property (nonatomic, copy, readonly) NSString *name;

+ (instancetype)commandWithName:(NSString *)name handler:(void (^)(NSDictionary *_Nullable data, KMMCompletion *completion))handler;

- (void)execute:(nullable NSDictionary *)data withCompletion:(KMMCompletion *)completion;

@end

NS_ASSUME_NONNULL_END
