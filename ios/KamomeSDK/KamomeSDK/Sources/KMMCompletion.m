//
// Copyright (c) 2018-present Hituzi Ando. All rights reserved.
//
// MIT License
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

@import WebKit;

#import "KMMCompletion.h"
#import "KMMMessenger.h"

@interface KMMCompletion ()

@property (nonatomic, weak) id webView;
@property (nonatomic, copy) NSString *name;
@property (nonatomic) BOOL completed;

@end

@implementation KMMCompletion

- (instancetype)initWithWebView:(id)webView name:(NSString *)name {
    self = [super init];

    if (self) {
        _webView = webView;
        _name = name;
    }

    return self;
}

- (void)complete {
    [self resolve];
}

- (void)completeWithDictionary:(NSDictionary *)data {
    [self resolveWithDictionary:data];
}

- (void)completeWithArray:(NSArray *)data {
    [self resolveWithArray:data];
}

- (void)resolve {
    [self resolveWithDictionary:nil];
}

- (void)resolveWithDictionary:(nullable NSDictionary *)data {
    if (self.completed) {
        return;
    }

    self.completed = YES;

    [[KMMMessenger sharedMessenger] completeMessageWithWebView:self.webView data:data forName:self.name];
}

- (void)resolveWithArray:(nullable NSArray *)data {
    if (self.completed) {
        return;
    }

    self.completed = YES;

    [[KMMMessenger sharedMessenger] completeMessageWithWebView:self.webView data:data forName:self.name];
}

- (void)reject {
    [self rejectWithErrorMessage:nil];
}

- (void)rejectWithErrorMessage:(nullable NSString *)errorMessage {
    if (self.completed) {
        return;
    }

    self.completed = YES;

    [[KMMMessenger sharedMessenger] failMessageWithWebView:self.webView error:errorMessage forName:self.name];
}

@end
