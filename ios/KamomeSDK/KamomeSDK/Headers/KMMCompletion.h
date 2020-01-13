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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class WKWebView;

@protocol KMMCompleting <NSObject>

- (BOOL)isCompleted;
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

@interface KMMCompletion : NSObject <KMMCompleting>

- (instancetype)initWithWebView:(__kindof WKWebView *)webView requestId:(NSString *)requestId;

@end

NS_ASSUME_NONNULL_END
