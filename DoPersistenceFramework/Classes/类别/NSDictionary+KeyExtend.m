//
//  NSDictionary+KeyExtend.m
//  MobileGuide
//
//  Created by 鞠 文杰 on 14-3-25.
//  Copyright (c) 2014年 CSICS. All rights reserved.
//

#import "NSDictionary+KeyExtend.h"

@implementation NSDictionary (KeyExtend)

- (BOOL)hasKey:(NSString *)keyName
{
    for (NSString *key in self.allKeys) {
        if ([key isEqualToString:keyName]) {
            return YES;
        }
    }
    return NO;
}

- (NSString *)convertToJSON
{
    NSMutableString *ret = [NSMutableString string];
    [ret appendString:@"["];
    
    [ret appendString:@"]"];
    return ret;
}

- (NSString *)convertToSQLPart
{
    NSMutableString *ret = [NSMutableString string];
    [ret appendString:@"["];
    
    [ret appendString:@"]"];
    return ret;
}

- (NSString *)convertToPostBody
{
    NSMutableString *ret = [NSMutableString string];
    [ret appendString:@"["];
    
    [ret appendString:@"]"];
    return ret;
}

@end
