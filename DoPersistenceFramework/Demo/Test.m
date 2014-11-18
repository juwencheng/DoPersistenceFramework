//
//  Test.m
//  DoPersistenceFramework
//
//  Created by Ju on 14/10/27.
//  Copyright (c) 2014年 scics. All rights reserved.
//

#import "Test.h"


@implementation Test

- (instancetype)init
{
    _arr = [[NSArray alloc] init];
    _arr.DPInternalClazz = @"Test1";
    self = [super init];
    if (self) {
        
    }
    return self;
}

@end
