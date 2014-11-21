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
    self = [super init];
    if (self) {
        
    }
    return self;
}

+ (NSDictionary *)collectionTypeInfo
{
    return
    @{
         @"arr":NSStringFromClass([Test1 class])
    };
}

@end
