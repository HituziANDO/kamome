//
// Created by Masaki Ando on 2018/07/07.
// Copyright (c) 2018 Hituzi Ando. All rights reserved.
//

@import WebKit;

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class KMMCommand;

@interface KMMUserContentController : WKUserContentController

@property (nonatomic, weak) WKWebView *webView;

- (void)addCommand:(KMMCommand *)command;

@end

NS_ASSUME_NONNULL_END
