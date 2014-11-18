//
//  NSString+DOTypeConvert.m
//  DOFramework
//
//  Created by ju on 14-5-13.
//  Copyright (c) 2014年 dono. All rights reserved.
//

#import "NSString+DOTypeConvert.h"
#import <objc/runtime.h>

@implementation NSString (DOTypeConvert)

- (NSString *)toDBType
{
    // not support collection type
    if ([self hasPrefix:@"@"]) {
        if ([[self lowercaseString] rangeOfString:@"string"].location != NSNotFound) {
            return @"TEXT";
//        }else if([[self lowercaseString] rangeOfString:@"date"].location!=NSNotFound){
//            return @"DATE";
        }else if([[self lowercaseString] rangeOfString:@"number"].location!=NSNotFound){
            return @"DOUBLE";
        }
    }else{
        if ([[self lowercaseString] isEqualToString:@"i"]
            ||[[self lowercaseString] isEqualToString:@"q"]
            ||[[self lowercaseString] isEqualToString:@"s"]
            ||[[self lowercaseString] isEqualToString:@"l"]) {
            return @"INTEGER";
        }else if([[self lowercaseString] isEqualToString:@"d"]){
            return @"DOUBLE";
        }else if([[self lowercaseString] isEqualToString:@"f"]){
            return @"FLOAT";
        }
    }
    return nil;
}

- (NSString *)toObjType
{
    
    return nil;
}

@end
