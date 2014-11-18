//
//  NSDictionary+KeyExtend.h
//  MobileGuide
//
//  Created by 鞠 文杰 on 14-3-25.
//  Copyright (c) 2014年 CSICS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (KeyExtend)

- (BOOL)hasKey:(NSString *)keyName;

- (NSString *)convertToJSON;

- (NSString *)convertToSQLPart;

- (NSString *)convertToPostBody;

@end
