//
//  Super.m
//  DoPersistenceFramework
//
//  Created by 鞠汶成 on 18/07/2017.
//  Copyright © 2017 scics. All rights reserved.
//

#import "Super.h"

@implementation Super

+ (void)test {
    @synchronized (self) {
        NSLog(@"%@ start", self);
        NSLog(@"xxx");
        [self syncOtherMethod];
        NSLog(@"%@ end", self);
    }
}

+ (void)syncOtherMethod {
    @synchronized (self) {
        NSLog(@"deadlock or not");
    }
}

@end
