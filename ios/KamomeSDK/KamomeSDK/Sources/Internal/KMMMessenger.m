//
// Created by Masaki Ando on 2018/07/07.
// Copyright (c) 2018 Hituzi Ando. All rights reserved.
//

@import WebKit;

#import "KMMMessenger.h"
#import "KMMException.h"

@interface KMMMessenger ()

@property (nonatomic, copy) NSMutableDictionary<NSString *, KMMReceiveResultBlock> *resultBlocks;

@end

@implementation KMMMessenger

+ (instancetype)sharedMessenger {
    static KMMMessenger *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [KMMMessenger new];
    });

    return instance;
}

- (instancetype)init {
    self = [super init];

    if (self) {
        _resultBlocks = [NSMutableDictionary new];
    }

    return self;
}

- (void)completeMessageWithWebView:(id)webView data:(nullable id)data forName:(NSString *)name {
    [self runJavaScript:@"window.Kamome.onComplete" withWebView:webView data:data callbackId:nil forName:name];
}

- (void)sendMessageWithWebView:(id)webView
                          data:(nullable id)data
                         block:(nullable KMMReceiveResultBlock)block
                    callbackId:(nullable NSString *)callbackId
                       forName:(NSString *)name {

    if (block && callbackId.length > 0) {
        @synchronized (self) {
            self.resultBlocks[callbackId] = [block copy];
        }
    }

    [self runJavaScript:@"window.Kamome.onReceive" withWebView:webView data:data callbackId:callbackId forName:name];
}

- (void)runJavaScript:(NSString *)funcName
          withWebView:(id)webView
                 data:(id)data
           callbackId:(NSString *)callbackId
              forName:(NSString *)name {

    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *js;

        if (data) {
            if (![NSJSONSerialization isValidJSONObject:data]) {
                @throw [KMMException exceptionWithReason:@"data is not valid." userInfo:nil];
            }

            NSString *params = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:data
                                                                                              options:0
                                                                                                error:nil]
                                                     encoding:NSUTF8StringEncoding];
            js = [NSString stringWithFormat:@"%@('%@', '%@', %@)",
                                            funcName, name, params, callbackId ? [NSString stringWithFormat:@"'%@'", callbackId] : @"null"];
        }
        else {
            js = [NSString stringWithFormat:@"%@('%@', null, %@)",
                                            funcName, name, callbackId ? [NSString stringWithFormat:@"'%@'", callbackId] : @"null"];
        }

        if ([webView isKindOfClass:[WKWebView class]]) {
            __weak typeof(self) weakSelf = self;

            [((WKWebView *) webView) evaluateJavaScript:js completionHandler:^(id value, NSError *error) {
                if (error) {
                    @throw [KMMException exceptionWithReason:[NSString stringWithFormat:@"%@ %@", error.localizedDescription, error.userInfo]
                                                    userInfo:nil];
                }

                if (value == [NSNull null] || ![value isKindOfClass:[NSString class]]) {
                    return;
                }

                NSString *str = (NSString *) value;

                if (str.length > 0 && ![@"null" isEqualToString:str.lowercaseString]) {
                    NSDictionary *obj = [NSJSONSerialization JSONObjectWithData:[str dataUsingEncoding:NSUTF8StringEncoding]
                                                                        options:NSJSONReadingAllowFragments
                                                                          error:nil];
                    NSString *cid = obj[@"callbackId"];
                    id result = obj[@"result"];

                    @synchronized (weakSelf) {
                        KMMReceiveResultBlock resultBlock = weakSelf.resultBlocks[cid];

                        if (resultBlock) {
                            resultBlock(result);

                            [weakSelf.resultBlocks removeObjectForKey:cid];
                            resultBlock = nil;
                        }
                    }
                }
            }];
        }
        else if ([webView isKindOfClass:[UIWebView class]]) {
            // MessageCallback not supported.
            [((UIWebView *) webView) stringByEvaluatingJavaScriptFromString:js];
        }
        else {
            @throw [KMMException exceptionWithReason:@"webView is not WKWebView or UIWebView instance." userInfo:nil];
        }
    });
}

@end
