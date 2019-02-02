//
// Created by Masaki Ando on 2018/07/06.
// Copyright (c) 2018 Hituzi Ando. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KMMCompletion : NSObject

@property (nonatomic, readonly, getter=isCompleted) BOOL completed;

- (instancetype)initWithWebView:(id)webView name:(NSString *)name;

- (void)complete DEPRECATED_MSG_ATTRIBUTE("Uses `resolve` method.");

- (void)completeWithDictionary:(nullable NSDictionary *)data DEPRECATED_MSG_ATTRIBUTE("Uses `resolveWithDictionary:` method.");

- (void)completeWithArray:(nullable NSArray *)data DEPRECATED_MSG_ATTRIBUTE("Uses `resolveWithArray:` method.");

- (void)resolve;

- (void)resolveWithDictionary:(nullable NSDictionary *)data;

- (void)resolveWithArray:(nullable NSArray *)data;

- (void)reject;

- (void)rejectWithErrorMessage:(nullable NSString *)errorMessage;

@end

NS_ASSUME_NONNULL_END
