//
//  DBAPI.m
//  DoPersistenceFramework
//
//  Created by Ju on 14/10/27.
//  Copyright (c) 2014年 scics. All rights reserved.
//

#import "DBMETA.h"

@implementation DBMETA

- (instancetype)init
{
    self = [super init];
    if (self) {
        _relation = [NSMutableSet set];
    }
    return self;
}

@end
