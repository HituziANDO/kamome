//
//  ViewController.m
//  Kamome
//
//  Created by Masaki Ando on 2018/07/05.
//  Copyright © 2018年 Hituzi Ando. All rights reserved.
//

#import <WebKit/WebKit.h>
#import <KamomeSDK/KamomeSDK.h>

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic) WKWebView *webView;
@property (nonatomic) KMMKamome *kamome;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Creates a kamome instance with default webView.
    WKWebView *webView = nil;
    self.kamome = [KMMKamome createInstanceAndWebView:&webView withFrame:self.view.frame];
    self.webView = webView;

    // Creates a kamome instance for a customized webView.
//    self.kamome = [KMMKamome new];
//
//    WKUserContentController *userContentController = [WKUserContentController new];
//    [userContentController addScriptMessageHandler:self.kamome name:KMMScriptMessageHandlerName];
//    WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
//    configuration.userContentController = userContentController;
//    self.webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:configuration];
//
//    [self.kamome setWebView:self.webView];

    [self.kamome addCommand:[KMMCommand commandWithName:@"echo" handler:^(NSDictionary *data, KMMCompletion *completion) {
        // Success
        [completion resolveWithDictionary:@{ @"message": data[@"message"] }];
    }]];

    [self.kamome addCommand:[KMMCommand commandWithName:@"get" handler:^(NSDictionary *data, KMMCompletion *completion) {
        // Failure
        [completion rejectWithErrorMessage:@"Error message"];
    }]];

    [self.kamome addCommand:[KMMCommand commandWithName:@"tooLong" handler:^(NSDictionary *data, KMMCompletion *completion) {
        // Too long process
        [NSTimer scheduledTimerWithTimeInterval:30.0 repeats:NO block:^(NSTimer *timer) {
            [completion resolve];
        }];
    }]];

    NSURL *htmlURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"index" ofType:@"html" inDirectory:@"www"]];
    [self.webView loadFileURL:htmlURL allowingReadAccessToURL:htmlURL];
    [self.view addSubview:self.webView];
    [self.view sendSubviewToBack:self.webView];
}

- (IBAction)sendButtonPressed:(id)sender {
    // Send data to JavaScript.
    [self.kamome sendMessageWithDictionary:@{ @"greeting": @"Hello!" }
                                     block:^(id result) {
                                         NSLog(@"result: %@", result);
                                     }
                                   forName:@"greeting"];
}

@end
