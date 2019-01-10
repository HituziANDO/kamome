//
// Created by Masaki Ando on 2018/07/08.
// Copyright (c) 2018 Hituzi Ando. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class WKWebViewConfiguration;
@class KMMCommand;
@class KMMUserContentController;

@interface KMMKamome : NSObject

@property (nonatomic, readonly) KMMUserContentController *userContentController;

- (void)setWebView:(id)webView;

- (instancetype)addCommand:(KMMCommand *)command;

- (void)sendMessageWithDictionary:(nullable NSDictionary *)data forName:(NSString *)name;

- (void)sendMessageWithArray:(nullable NSArray *)data forName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
