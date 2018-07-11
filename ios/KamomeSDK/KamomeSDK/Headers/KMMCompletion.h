//
// Created by Masaki Ando on 2018/07/06.
// Copyright (c) 2018 Hituzi Ando. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KMMCompletion : NSObject

@property (nonatomic, readonly, getter=isCompleted) BOOL completed;

- (instancetype)initWithWebView:(id)webView name:(NSString *)name;

- (void)complete;

- (void)completeWithData:(nullable NSDictionary *)data;

@end

NS_ASSUME_NONNULL_END
