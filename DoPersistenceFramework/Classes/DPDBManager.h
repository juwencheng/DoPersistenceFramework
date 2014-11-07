//
//  DPDBManager.h
//  DoPersistenceFramework
//
//  Created by Ju on 14/11/3.
//  Copyright (c) 2014年 scics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DBMETA.h"
#import "DPConstants.h"
#import <sqlite3.h>

@interface DPDBManager : NSObject

+ (sqlite3 *)database;

+ (void)setDBPath:(NSString *)dbpath;

+ (DPDBManager *)singleton;

+ (NSInteger)seqWithClazz:(NSString *)classname;

@property (nonatomic,strong) NSMutableDictionary *metaInfos;

@end
