//
// Created by Masaki Ando on 2018/07/08.
// Copyright (c) 2018 Hituzi Ando. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@class KMMCommand;
@class KMMUserContentController;

UIKIT_EXTERN NSString *const KMMScriptMessageHandlerName;

@interface KMMKamome : NSObject <WKScriptMessageHandler>

@property (nonatomic, readonly) KMMUserContentController *userContentController DEPRECATED_ATTRIBUTE;

/**
 * Creates a KMMKamome instance and a default WKWebView instance initialized by Kamome.

 * @param webView Returns a WKWebView instance created by Kamome.
 * @param frame A webView's frame.
 * @return Returns a KMMKamome instance.
 */
+ (instancetype)createInstanceAndWebView:(WKWebView **)webView withFrame:(CGRect)frame;

- (void)setWebView:(id)webView;

- (instancetype)addCommand:(KMMCommand *)command;

- (void)sendMessageWithBlock:(nullable void (^)(id _Nullable result))block forName:(NSString *)name;

- (void)sendMessageWithDictionary:(nullable NSDictionary *)data
                            block:(nullable void (^)(id _Nullable result))block
                          forName:(NSString *)name;

- (void)sendMessageWithArray:(nullable NSArray *)data
                       block:(nullable void (^)(id _Nullable result))block
                     forName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
