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

    self.kamome = [KMMKamome new];

    WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
    configuration.userContentController = self.kamome.userContentController;
    self.webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:configuration];

    [self.kamome setWebView:self.webView];

    [self.kamome addCommand:[KMMCommand commandWithName:@"echo" handler:^(NSDictionary *data, KMMCompletion *completion) {
        [completion completeWithDictionary:@{ @"message": data[@"message"] }];
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
