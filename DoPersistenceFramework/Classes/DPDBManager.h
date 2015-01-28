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

/**
 *  获得数据库对象
 *
 *  @return 数据库对象
 */
+ (sqlite3 *)database;

/**
 *  设置数据库文件位置，需要在调用+database之前设置
 *
 *  @param dbpath 设置数据库位置
 */
+ (void)setDBPath:(NSString *)dbpath;

/**
 *  DPDBManager 单例对象
 *
 *  @return 单例对象
 */
+ (DPDBManager *)singleton;

/**
 *  根据类名查询序列号
 *
 *  @param classname 类名
 *
 *  @return 序列值
 */
+ (NSInteger)seqWithClazz:(NSString *)classname;


@property (nonatomic,strong) NSMutableDictionary *metaInfos;

@end
