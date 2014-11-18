//
//  DPDBManager.m
//  DoPersistenceFramework
//
//  Created by Ju on 14/11/3.
//  Copyright (c) 2014年 scics. All rights reserved.
//

#import "DPDBManager.h"
#import "NSDictionary+KeyExtend.h"
#import "DPDBObject.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@implementation DPDBManager
{
    sqlite3 *database;
    NSString *dbPath;
    NSFileManager *fileMgr;
    NSMutableDictionary *primaryKeyIndexs;
}

+ (DPDBManager *)singleton
{
    static dispatch_once_t onceToken;
    static DPDBManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] initInternal];
    });
    return instance;
}

- (id)initInternal
{
    self = [self init];
    if (self) {
        fileMgr = [[NSFileManager alloc] init];
        _metaInfos = [NSMutableDictionary dictionary];
        primaryKeyIndexs = [NSMutableDictionary dictionary];
        [self setupMetaTable];
        [self registNotification];
    }
    return self;
}

- (void)setupMetaTable
{
    //初始化全局表
    int result;
    char *errmsg = NULL;
    sqlite3 *db = [self database];
    if ((result = sqlite3_exec(db, [@"CREATE TABLE IF NOT EXISTS PKSEQ (name varchar(50) PRIMARY KEY,SEQ INTEGER)" UTF8String], NULL, NULL, &errmsg)) != SQLITE_OK) {
        NSLog(@"创建序列表错误:%s 错误代码:%d",errmsg,result);
    }
}

+ (sqlite3 *)database
{
    return [[[self class] singleton] database];
}

- (sqlite3 *)database
{
    static BOOL first = YES;
    if (first || database == NULL) {
        //        NSLog(@"database open");
        if (!dbPath) {
            dbPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"database.db"];
            NSLog(@"%@",dbPath);
            if (![fileMgr fileExistsAtPath:dbPath]) {
                [fileMgr createFileAtPath:dbPath contents:nil attributes:nil];
            }
            //
            //            NSLog(@"%@",dbPath);
        }
        first = NO;
        if (sqlite3_open([dbPath UTF8String], &database) != SQLITE_OK) {
            NSAssert(NO, @"打开数据库失败");
            sqlite3_close(database);
        }
//        [self checkDBMetaInfo];
        //create some table about database and util table
        //
    }
    return database;
}

+ (NSInteger)seqWithClazz:(NSString *)classname
{
    return [[self singleton] seqWithClazz:classname];
    
}

- (NSInteger)seqWithClazz:(NSString *)classname
{
    
    @synchronized(primaryKeyIndexs)
    {
        if (![primaryKeyIndexs hasKey:classname]) {
            Class clazz = NSClassFromString(classname);
            if ([clazz isSubclassOfClass:[DPDBObject class]]) {
                [primaryKeyIndexs setObject:[NSNumber numberWithInteger:[clazz currentSeq]] forKey:classname];
            }
            
        }
        NSInteger index = [[primaryKeyIndexs objectForKey:classname] integerValue];
        [primaryKeyIndexs setObject:[NSNumber numberWithInteger:index+1] forKey:classname];
        return index;
    }
}

- (void)registNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(persistPkInfo:) name:UIApplicationWillTerminateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(persistPkInfo:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadPkInfo:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)persistPkInfo:(NSNotification *)notification
{
    NSLog(@"persistPkInfo");
    NSArray *classnameCollection = primaryKeyIndexs.allKeys;
    for (NSString *classname in classnameCollection) {
        Class clazz = NSClassFromString(classname);
        if ([clazz isSubclassOfClass:[DPDBObject class]]) {
            [clazz syncSeq:[[primaryKeyIndexs objectForKey:classname] integerValue]];
        }else{
            [primaryKeyIndexs removeObjectForKey:classname];
        }
    }
}

- (void)loadPkInfo:(NSNotification *)notification
{
    NSArray *classnameCollection = primaryKeyIndexs.allKeys;
    for (NSString *classname in classnameCollection) {
        Class clazz = NSClassFromString(classname);
        if ([clazz isSubclassOfClass:[DPDBObject class]]) {
            [primaryKeyIndexs setObject:[NSNumber numberWithInteger:[clazz currentSeq]] forKey:classname];
        }else{
            [primaryKeyIndexs removeObjectForKey:classname];
        }
    }
}

+ (void)setDBPath:(NSString *)dbpath
{
    [[self singleton] setDBPath:dbpath];
}

- (void)setDBPath:(NSString *)dbpath
{
    dbpath = dbpath;
}

@end
