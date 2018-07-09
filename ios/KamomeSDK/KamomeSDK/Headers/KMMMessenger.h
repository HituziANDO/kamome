//
// Created by Masaki Ando on 2018/07/07.
// Copyright (c) 2018 Hituzi Ando. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KMMMessenger : NSObject

+ (void)sendMessageWithWebView:(id)webView data:(nullable NSDictionary *)data forName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
