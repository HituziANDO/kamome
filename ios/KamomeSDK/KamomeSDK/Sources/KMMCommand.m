//
// Created by Masaki Ando on 2018/07/05.
// Copyright (c) 2018 Hituzi Ando. All rights reserved.
//

#import "KMMCommand.h"
#import "KMMCompletion.h"

typedef void (^Handler)(NSDictionary *_Nullable, KMMCompletion *);

@interface KMMCommand ()

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) Handler handler;

@end

@implementation KMMCommand

+ (instancetype)commandWithName:(NSString *)name handler:(void (^)(NSDictionary *_Nullable data, KMMCompletion *completion))handler {
    KMMCommand *command = [KMMCommand new];
    command.name = name;
    command.handler = handler;
    return command;
}

- (void)dealloc {
    self.handler = nil;
}

- (void)execute:(NSDictionary *)data withCompletion:(KMMCompletion *)completion {
    if (self.handler) {
        self.handler(data, completion);
    }
}

@end
