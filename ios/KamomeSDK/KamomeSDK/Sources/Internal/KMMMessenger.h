//
// Created by Masaki Ando on 2018/07/07.
// Copyright (c) 2018 Hituzi Ando. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^KMMReceiveResultBlock)(id _Nullable result);

@interface KMMMessenger : NSObject

+ (instancetype)sharedMessenger;

- (void)completeMessageWithWebView:(id)webView data:(nullable id)data forName:(NSString *)name;

- (void)sendMessageWithWebView:(id)webView
                          data:(nullable id)data
                         block:(nullable KMMReceiveResultBlock)block
                    callbackId:(nullable NSString *)callbackId
                       forName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
