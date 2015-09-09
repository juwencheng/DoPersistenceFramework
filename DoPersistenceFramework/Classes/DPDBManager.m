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
#import "DPConstants.h"

@interface DPDBManager ()

@property (nonatomic, strong) NSString *dbPath;
@property (nonatomic, assign) sqlite3 *database;

@end

@implementation DPDBManager {
    NSFileManager *fileMgr;
    NSMutableDictionary *primaryKeyIndexs;
}

+ (DPDBManager *)singleton {
    static dispatch_once_t onceToken;
    static DPDBManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] initInternal];
    });
    return instance;
}

- (id)initInternal {
    self = [self init];
    if (self) {
        fileMgr = [[NSFileManager alloc] init];
        _metaInfos = [NSMutableDictionary dictionary];
        primaryKeyIndexs = [NSMutableDictionary dictionary];
        
        if (!_dbPath) {
            _dbPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"database.db"];
#if sqlDebug
            NSLog(@"数据库文件保存位置 : %@",_dbPath);
#endif
            if (![fileMgr fileExistsAtPath:_dbPath]) {
                [fileMgr createFileAtPath:_dbPath contents:nil attributes:nil];
            }
        }
        
        [self setupMetaTable];
        [self registNotification];
    }
    return self;
}

- (void)setupMetaTable {
#if sqlDebug
    NSLog(@"创建 PKSEQ 表和 tableRelation 表");
#endif
    //初始化全局表
    int result;
    char *errmsg = NULL;
    sqlite3 *db = [self database];
    if ((result = sqlite3_exec(db, [@"CREATE TABLE IF NOT EXISTS PKSEQ (name varchar(50) PRIMARY KEY,SEQ INTEGER)" UTF8String], NULL, NULL, &errmsg)) != SQLITE_OK) {
#if sqlDebug
        NSLog(@"创建序列表错误:%s 错误代码:%d",errmsg,result);
#endif
    }
    
    //创建关系记录表
    if ((result = sqlite3_exec(db, [@"CREATE TABLE IF NOT EXISTS tableRelation (pk integer auto_increment primary key , tablename varchar(50) , relationtablename varchar(50))" UTF8String], NULL, NULL, &errmsg))) {
#if sqlDebug
        NSLog(@"创建关系记录表错误:%s 错误代码:%d",errmsg,result);
#endif
    }
}

+ (sqlite3 *)database {
    return [[[self class] singleton] database];
}

+ (NSInteger)seqWithClazz:(NSString *)classname {
    return [[self singleton] seqWithClazz:classname];
}

- (NSInteger)seqWithClazz:(NSString *)classname
{
    @synchronized(primaryKeyIndexs) {
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

- (void)registNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(persistPkInfo:) name:UIApplicationWillTerminateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(persistPkInfo:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadPkInfo:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)persistPkInfo:(NSNotification *)notification
{
#if sqlDebug
    NSLog(@"保存主键值游标到数据库");
#endif
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

- (void)loadPkInfo:(NSNotification *)notification {
#if sqlDebug
    NSLog(@"从数据库加载主键值游标到内存");
#endif
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

+ (void)setDBPath:(NSString *)dbpath {
    [[self singleton] setDbPath:dbpath];
}

#pragma mark - 属性
- (sqlite3 *)database {
    if (_database == NULL) {
#if sqlDebug
        NSLog(@"打开数据库...");
#endif
        if (sqlite3_open([_dbPath UTF8String], &_database) != SQLITE_OK) {
            NSAssert(NO, @"打开数据库失败");
            sqlite3_close(_database);
        }
    }
    return _database;
}


@end
