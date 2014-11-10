//
//  DPDBObject.h
//  DoPersistenceFramework
//
//  Created by Ju on 14/10/27.
//  Copyright (c) 2014年 scics. All rights reserved.
//

#import <Foundation/Foundation.h>

#define isCollectionType(x) (isNSSetType(x) || isNSArrayType(x) || isNSDictionaryType(x))
#define isNSArrayType(x) ([x isEqualToString:@"NSArray"] || [x isEqualToString:@"NSMutableArray"])
#define isNSDictionaryType(x) ([x isEqualToString:@"NSDictionary"] || [x isEqualToString:@"NSMutableDictionary"])
#define isNSSetType(x) ([x isEqualToString:@"NSSet"] || [x isEqualToString:@"NSMutableSet"])
#define isNSStringType(x) ([x isEqualToString:@"NSString"] || [x isEqualToString:@"NSMutableString"])

@interface DPDBObject : NSObject

//包括更新方法
- (void)save;

- (NSError *)deleteMe;

- (NSInteger)pk;

//+ (DPDBObject *)queryByPk:(NSInteger)pk;

+ (NSArray *)allObjects;

+ (void)deleteAll;

+ (void)syncSeq:(NSInteger)seq;

+ (NSInteger)currentSeq;

@end
