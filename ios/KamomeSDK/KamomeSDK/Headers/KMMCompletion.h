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
/**
 * Sends resolved result to a JavaScript callback function.
 */
- (void)resolve;
/**
 * Sends resolved result with a dictionary data to a JavaScript callback function.
 *
 * @param data A dictionary data.
 */
- (void)resolveWithDictionary:(nullable NSDictionary *)data;
/**
 * Sends resolved result with an array data to a JavaScript callback function.
 *
 * @param data An array data.
 */
- (void)resolveWithArray:(nullable NSArray *)data;
/**
 * Sends rejected result to a JavaScript callback function.
 */
- (void)reject;
/**
 * Sends rejected result with an error message to a JavaScript callback function.
 *
 * @param errorMessage An error message.
 */
- (void)rejectWithErrorMessage:(nullable NSString *)errorMessage NS_SWIFT_NAME(reject(with:));

@end

NS_ASSUME_NONNULL_END
