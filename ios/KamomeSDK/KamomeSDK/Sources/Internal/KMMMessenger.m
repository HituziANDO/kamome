//
// Created by Masaki Ando on 2018/07/07.
// Copyright (c) 2018 Hituzi Ando. All rights reserved.
//

@import WebKit;

#import "KMMMessenger.h"
#import "KMMException.h"

@implementation KMMMessenger

+ (void)completeMessageWithWebView:(id)webView data:(NSDictionary *)data forName:(NSString *)name {
        [self runJavaScript:@"window.Kamome.onComplete" withWebView:webView data:data forName:name];
}

+ (void)sendMessageWithWebView:(id)webView data:(NSDictionary *)data forName:(NSString *)name {
    [self runJavaScript:@"window.Kamome.onReceive" withWebView:webView data:data forName:name];
}

+ (void)runJavaScript:(NSString *)funcName withWebView:(id)webView data:(NSDictionary *)data forName:(NSString *)name {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *js;
        
        if (data) {
            NSString *params = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:data
                                                                                              options:0
                                                                                                error:nil]
                                                     encoding:NSUTF8StringEncoding];
            js = [NSString stringWithFormat:@"%@('%@', '%@')", funcName, name, params];
        }
        else {
            js = [NSString stringWithFormat:@"%@('%@', null)", funcName, name];
        }
        
        if ([webView isKindOfClass:[WKWebView class]]) {
            [((WKWebView *) webView) evaluateJavaScript:js completionHandler:^(id o, NSError *error) {
                if (error) {
                    @throw [KMMException exceptionWithReason:[NSString stringWithFormat:@"%@ %@", error.localizedDescription, error.userInfo]
                                                    userInfo:nil];
                }
            }];
        }
        else if ([webView isKindOfClass:[UIWebView class]]) {
            [((UIWebView *) webView) stringByEvaluatingJavaScriptFromString:js];
        }
        else {
            @throw [KMMException exceptionWithReason:@"webView is not WKWebView or UIWebView instance." userInfo:nil];
        }
    });
}

@end
