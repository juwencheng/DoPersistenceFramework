//
//  DPDBObject.m
//  DoPersistenceFramework
//
//  Created by Ju on 14/10/27.
//  Copyright (c) 2014年 scics. All rights reserved.
//

#import "DPDBObject.h"
#import <objc/runtime.h>
#import "DPDBManager.h"
#import "DBMETA.h"
#import "DBMETAPROP.h"

@implementation DPDBObject
{
    DBMETA *classMeta;
    
    @private
        NSInteger pk;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        pk = -1;
        [[self class] buildMeta];
        classMeta = [[[DPDBManager singleton] metaInfos] objectForKey:NSStringFromClass([self class])];
        if (!classMeta.buildRelation) {
            for (DBMETAPROP *pMeta in classMeta.props) {
                if (pMeta.transient) {
                    /*
                     要在运行时
                     if ([pMeta.obType isEqualToString:@"ARRAY"]
                     || [pMeta.obType isEqualToString:@"SET"]) {
                     //一对多关系
                     
                     }
                     */
                    //创建相应的表格
                    
                    if(isNSArrayType(pMeta.obType)
                       ||isNSSetType(pMeta.obType)){
                        if (!pMeta.obInternalType) {
                            NSArray *tmpArr = [self valueForKey:pMeta.propName];
                            if ([tmpArr respondsToSelector:@selector(DPInternalClazz)]) {
                                pMeta.obInternalType = tmpArr.DPInternalClazz;
                                if (pMeta.obInternalType!=nil || ![pMeta.obInternalType isEqualToString:@""]) {
                                    [classMeta.relation addObject:pMeta.obInternalType];
                                }else{
                                    NSLog(@"类 %@ 的属性 %@没有实现 DPInternalClazz 方法",classMeta.tablename,pMeta.propName);
                                }
                            }
                            
                        }
                    }
                    
                }
            }
            classMeta.buildRelation = YES;
        }
    }
    return self;
}

- (NSInteger)pk
{
    return pk;
}

- (void)setPK:(NSInteger)thePK
{
    pk = thePK ;
}

- (void)save
{
    sqlite3 *db = [DPDBManager database];
    [[self class] doInternalSave:self database:db classMeta:classMeta];
}

- (NSError *)deleteMe
{
    if (pk<0) {
        return nil;
    }
    //关联删除
    sqlite3 *db = [DPDBManager database];
    [[self class] doInternalDeleteByPk:pk meta:classMeta fromDB:db];
    
    return nil;
}

+ (void)doInternalDeleteByPk:(NSInteger)pk
                        meta:(DBMETA *)meta
                      fromDB:(sqlite3 *)db
{
    if (pk < 0) {
        return;
    }
    
    //关联删除
    [self deleteRelationsByParentId:pk meta:meta fromDB:db];
    
    NSString *deleteSql = [NSString stringWithFormat:@"%@ WHERE pk = %lu",meta.del,(long)pk];
    char *errmsg = NULL;
    int result;
    if ((result = sqlite3_exec(db, [deleteSql UTF8String], NULL, NULL, &errmsg))!=SQLITE_OK) {
        NSLog(@"删除表%@中记录失败,PK : %lu  errorCode : %d",meta.tablename,pk,result);
    }
}

+ (void)deleteRelationsByParentId:(NSInteger)parentId
                             meta:(DBMETA *)meta
                           fromDB:(sqlite3 *)db
{
    char *errmsg = NULL;
    int result ;
    if (parentId < 0) {
        for (NSString *relationTablename in meta.relation) {
            
            NSArray *relationModelPks = [self queryRelationsByParentId:parentId parentTablename:meta.tablename childTablename:relationTablename fromDB:db];
            if ([NSClassFromString(relationTablename) isSubclassOfClass:[DPDBObject class]]) {
                [NSClassFromString(relationTablename) deleteByPks:relationModelPks];
            }
            
            NSString *insertRelation = [NSString stringWithFormat:@"delete from %@_%@ ",meta.tablename,relationTablename];
            if ((result = sqlite3_exec(db, [insertRelation UTF8String], NULL, NULL, &errmsg))!=SQLITE_OK) {
                NSLog(@"根据关联ID删除关系失败 : %@_%@  errorCode : %d",meta.tablename,relationTablename,result);
            }else{
                NSLog(@"根据关联ID删除关系成功表: %@_%@ ",meta.tablename,relationTablename);
            }
        }
    }else{
        for (NSString *relationTablename in meta.relation) {
            NSString *insertRelation = [NSString stringWithFormat:@"delete from %@_%@ where parent_id = %ld",meta.tablename,relationTablename,(long)parentId];
            if ((result = sqlite3_exec(db, [insertRelation UTF8String], NULL, NULL, &errmsg))!=SQLITE_OK) {
                NSLog(@"根据关联ID删除关系失败 : %@_%@  errorCode : %d",meta.tablename,relationTablename,result);
            }else{
                NSLog(@"根据关联ID删除关系成功表: %@_%@ ",meta.tablename,relationTablename);
            }
        }
    }
    
}

//核心是遍历
//构建tableview的元信息
+ (void)buildMeta
{
    static BOOL refTableCreateFlag = NO;
    DBMETA *meta = [[[DPDBManager singleton] metaInfos] objectForKey:NSStringFromClass([self class])];
    if (meta) {
        return;
    }
    
    meta = [[DBMETA alloc] init];
    meta.tablename = NSStringFromClass([self class]);
    
    NSDictionary *d = [self classPropertiesWithType];
    
    //排序
    [d.allKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2 options:NSLiteralSearch];
    }];
    NSMutableArray *propsmeta = [NSMutableArray array];
    
    //遍历属性
    for (NSString *propname in d.allKeys) {
        DBMETAPROP *propmeta = [[DBMETAPROP alloc] init];
        propmeta.propName = propname;
        propmeta.transient = NO;
        NSString *proptype = [d objectForKey:propname];
        //基础类型
        if ([proptype rangeOfString:@"@"].location == NSNotFound) {
            if ([proptype isEqualToString:@"i"] || // int
                [proptype isEqualToString:@"I"] || // unsigned int
                [proptype isEqualToString:@"l"] || // long
                [proptype isEqualToString:@"L"] || // usigned long
                [proptype isEqualToString:@"q"] || // long long
                [proptype isEqualToString:@"Q"] || // unsigned long long
                [proptype isEqualToString:@"s"] || // short
                [proptype isEqualToString:@"S"] ||  // unsigned short
                [proptype isEqualToString:@"B"] )   // bool or _Bool
            {
                propmeta.dbtype = @"INTEGER";
                propmeta.obType = @"NUMBER";
            }else if ([proptype isEqualToString:@"c"] ||	// char
                      [proptype isEqualToString:@"C"] )  // unsigned char
            {
                propmeta.dbtype = @"TEXT";
                propmeta.obType = proptype;
            }
            else if ([proptype isEqualToString:@"f"] || // float
                     [proptype isEqualToString:@"d"] )  // double
            {
                propmeta.dbtype = @"REAL";
                propmeta.obType = proptype;
            }
        }else{
            NSString *className = [proptype substringWithRange:NSMakeRange(2, [proptype length]-3)];
            if (isNSArrayType(className)) {
                propmeta.transient = YES;
                propmeta.obType = @"NSArray";
            }else if(isNSSetType(className)){
                propmeta.transient = YES;
                propmeta.obType = @"NSSet";
            }else if(isNSDictionaryType(className)){
                propmeta.transient = YES;
                propmeta.obType = @"NSDictionary";
            }else if(isNSStringType(className)){
                propmeta.obType = @"NSString";
                propmeta.dbtype = @"TEXT";
            }
            else{
                propmeta.obType = className;
                propmeta.transient = YES;
            }
        }
        
        [propsmeta addObject:propmeta];
    }
    meta.props = propsmeta;
    NSMutableString *ins = [NSMutableString string];
    NSMutableString *ins_1 = [NSMutableString string];
    NSMutableString *update = [NSMutableString string];
    NSMutableString *create = [NSMutableString string];

    for (DBMETAPROP *pMeta in meta.props) {
        if (!pMeta.transient) {
            [create appendString:[NSString stringWithFormat:@"%@ %@ ,",pMeta.propName,pMeta.dbtype]];
            [ins appendString:[NSString stringWithFormat:@"%@ ,",pMeta.propName]];
            [ins_1 appendString:[NSString stringWithFormat:@" ? ,"]];
            [update appendString:[NSString stringWithFormat:@"set %@ = ?,",pMeta.propName]];
        }
        else{
            /*
             要在运行时
             if ([pMeta.obType isEqualToString:@"ARRAY"]
             || [pMeta.obType isEqualToString:@"SET"]) {
             //一对多关系
             
             }
             */
            //创建相应的表格
            if(isNSArrayType(pMeta.obType)
               ||isNSSetType(pMeta.obType)){
                
            }else {
                Class clazz = NSClassFromString(pMeta.obType);
                if ([clazz isSubclassOfClass:[DPDBObject class]]) {
                    //创建关系表
                    NSString *refInsert = [NSString stringWithFormat:@"create table if not exists %@_%@ (pk integer  auto_increment primary key, parent_id integer, child_id integer);",meta.tablename,pMeta.obType];
//                    NSLog(@"%@",refInsert);
                    //执行create
                    sqlite3 *db = [DPDBManager database];
                    char *errmsg = NULL;
                    int result ;
                    if ((result = sqlite3_exec(db, [refInsert UTF8String], NULL, NULL, &errmsg))!=SQLITE_OK) {
                        NSLog(@"创建表失败 : %@_%@  errorCode : %d",meta.tablename,pMeta.obType,result);
                    }else{
                        NSLog(@"表: %@_%@ 创建成功",meta.tablename,pMeta.obType);
                    }
                    
                    
                    [meta.relation addObject:pMeta.obType];
                }else{
                    //创建关系关联表
                    if (!refTableCreateFlag) {
                        refTableCreateFlag = !refTableCreateFlag;
                        NSString *createRefTable = [NSString stringWithFormat:@"create table if not exists tableRelation (tablename TEXT, relationtablename TEXT)"];
                        sqlite3 *db = [DPDBManager database];
                        char *errmsg = NULL;
                        int result ;
                        if ((result = sqlite3_exec(db, [createRefTable UTF8String], NULL, NULL, &errmsg))!=SQLITE_OK) {
                            NSLog(@"创建失败关联表");
                        }else{
                            NSLog(@"创建成功关联表");
                        }
                    }
                }
            }
        }
    }
    meta.insert = [NSString stringWithFormat:@"insert into %@ (pk,%@ ) values (? ,%@ )",meta.tablename,[ins substringToIndex:(ins.length-1)],[ins_1 substringToIndex:(ins_1.length-1)]];
    meta.create = [NSString stringWithFormat:@"create table if not exists %@ (pk integer primary key , %@ )",meta.tablename,[create substringToIndex:create.length-1]];
    meta.update = [NSString stringWithFormat:@"update %@ %@ where pk = ?",meta.tablename,[update substringToIndex:update.length-1]];
    meta.query = [NSString stringWithFormat:@"select pk , %@ from %@",[ins substringToIndex:(ins.length-1)],meta.tablename];
    meta.del = [NSString stringWithFormat:@"delete from %@",meta.tablename];
    
    
    
    //执行SQL
    char *errmsg = NULL;
    sqlite3 *db = [DPDBManager database];
    
    if (sqlite3_exec(db, [meta.create UTF8String], NULL, NULL, &errmsg)!=SQLITE_OK) {
        NSAssert(NO, @"创建表失败");
    }
    
    NSMutableString *addSequenceSQL = [NSMutableString stringWithFormat:@"INSERT OR IGNORE INTO PKSEQ (name,seq) VALUES('%@',0)",meta.tablename];
    if (sqlite3_exec(db, [addSequenceSQL UTF8String], NULL, NULL, &errmsg)!=SQLITE_OK) {
        NSLog(@"初始化%@的pkseq失败",meta.tablename);
    }
    
    
    sqlite3_stmt *stmt;
    NSMutableSet *relation = [NSMutableSet set];
    if (sqlite3_prepare_v2(db, [[NSString stringWithFormat:@"select relationtablename from tableRelation where tablename = '%@'",meta.tablename] UTF8String], -1, &stmt, nil) == SQLITE_OK) {
        int ret ;
        while ((ret = sqlite3_step(stmt)) == SQLITE_ROW) {
            const char *relationTable = (char *)sqlite3_column_text(stmt, 0);
            if (relationTable!=NULL) {
                [relation addObject:[NSString stringWithUTF8String:relationTable]];
            }
        }
    }
    
#warning 应该和目前的进行比较，如果有改动就进行删除操作
    [meta.relation intersectSet:relation];
    
    
    
    [[[DPDBManager singleton] metaInfos] setObject:meta forKey:meta.tablename];
}

+ (DPDBObject *)queryByPk:(NSInteger)pk
{
    if (pk<0) {
        return nil;
    }
    id model ;
    
    [self buildAndCheckMeta];
    sqlite3 *db = [DPDBManager database];
    DBMETA *meta = [[[DPDBManager singleton] metaInfos] objectForKey:NSStringFromClass([self class])];
    
    NSString *query = [meta.query stringByAppendingFormat:@" where pk = %ld",(long)pk];
    NSArray *result = [self doInternalQuery:query database:db classMeta:meta];
    if (result.count >= 1) {
        model = result[0];
    }
    return model;
}

+ (id)doInternalQuery:(NSString *)query
             database:(sqlite3 *)db
//            statement:(sqlite3_stmt *)stmt
            classMeta:(DBMETA *)meta
{
    sqlite3_stmt *stmt;
    NSMutableArray *result = [NSMutableArray array];
    NSArray *props = meta.props;
    if (sqlite3_prepare_v2(db, [query UTF8String], -1, &stmt, nil) == SQLITE_OK) {
        id model;
        int ret ;
        while ((ret = sqlite3_step(stmt)) == SQLITE_ROW) {
            model = [[[self class] alloc] init];
            NSString *type;
            NSString *name;
            int position = 0;
            DBMETAPROP *prop;
            //            [model setValue:[NSNumber numberWithInt:sqlite3_column_int(stmt, position++)] forKey:@"pk"];
            NSInteger thePk =sqlite3_column_int(stmt, position++);
            [model setPK:thePk];
            for (long i=0,len=props.count; i<len; i++) {
                prop = props[i];
                name = prop.propName;
                type = prop.dbtype;
                if (!prop.transient) {
                    if (type != nil) {
                        if ([[type lowercaseString] isEqualToString:@"integer"]
                            || [[type lowercaseString] isEqualToString:@"double"]
                            || [[type lowercaseString ] isEqualToString:@"float"]
                            || [[type lowercaseString] isEqualToString:@"real"]) {
                            [model setValue:[NSNumber numberWithInt: sqlite3_column_int(stmt, position)] forKey:name];
                        }else if([[type lowercaseString] isEqualToString:@"text"]){
                            const char *columnValue =(char *) sqlite3_column_text(stmt, position);
                            columnValue = (columnValue == NULL)?"":columnValue;
                            [model setValue:[NSString stringWithUTF8String:columnValue] forKey:name];
                        }
                        else{
                            NSLog(@"%@ 类型暂未实现",type);
                        }
                        position ++;
                    }
                }else{
                    if (isCollectionType(prop.obType)) {
                        if (isNSArrayType(prop.obType)) {
                            if (!prop.obInternalType) {
                                NSArray *tmpArr = [model valueForKey:prop.propName];
                                if ([tmpArr respondsToSelector:@selector(DPInternalClazz)]) {
                                    prop.obInternalType = tmpArr.DPInternalClazz;
                                    if (!prop.obInternalType) {
                                        [meta.relation addObject:prop.obInternalType];
                                    }
                                }
                                
                            }
                            if (!prop.obInternalType) {
                                NSLog(@"类%@中的属性 %@ 没有设置迭代元素的类类型",meta.tablename,prop.propName);
                            }else{
                                NSArray *relationModelPks = [self queryRelationsByParentId:thePk parentTablename:meta.tablename childTablename:prop.obInternalType fromDB:db];
                                NSMutableArray *propValue = [NSMutableArray array];
                                if (relationModelPks.count > 0) {
                                    for (NSNumber *number in relationModelPks) {
                                        id refModel = [NSClassFromString(prop.obInternalType) queryByPk:[number integerValue]];
                                        [propValue addObject:refModel];
                                    }
                                    [model setValue:propValue forKey:prop.propName];
                                }
                            }
                            
                        }else if (isNSSetType(prop.obType)){
                            if (!prop.obInternalType) {
                                NSSet *tmpSet = [model valueForKey:prop.propName];
                                if ([tmpSet respondsToSelector:@selector(DPInternalClazz)]) {
                                    prop.obInternalType = tmpSet.DPInternalClazz;
                                    if (!prop.obInternalType) {
                                        [meta.relation addObject:prop.obInternalType];
                                    }
                                }
                            }
                            if (!prop.obInternalType) {
                                NSLog(@"类%@中的属性 %@ 没有设置迭代元素的类类型",meta.tablename,prop.propName);
                            }else{
                                NSArray *relationModelPks = [self queryRelationsByParentId:thePk parentTablename:meta.tablename childTablename:prop.obInternalType fromDB:db];
                                NSMutableArray *propValue = [NSMutableArray array];
                                if (relationModelPks.count > 0) {
                                    for (NSNumber *number in relationModelPks) {
                                        id refModel = [NSClassFromString(prop.obInternalType) queryByPk:[number integerValue]];
                                        [propValue addObject:refModel];
                                    }
                                    [model setValue:[NSSet setWithArray:propValue] forKey:prop.propName];
                                }
                            }
                        }
                    }else if([NSClassFromString(prop.obType) isSubclassOfClass:[DPDBObject class]]){
                        NSInteger refPk = 0;
                        NSArray *relationModelPks = [self queryRelationsByParentId:thePk parentTablename:meta.tablename childTablename:prop.obType fromDB:db];
                        if (relationModelPks.count > 0) {
                            refPk = [relationModelPks[0] integerValue];
                            if (refPk != 0) {
                                id refModel = [NSClassFromString(prop.obType) queryByPk:refPk];
                                [model setValue:refModel forKey:prop.propName];
                            }
                        }
                    }
                }
            }
            [result addObject:model];
        }
    }
    sqlite3_finalize(stmt);
    return result;
}

+ (NSArray *)queryRelationsByParentId:(NSInteger)parentId
                      parentTablename:(NSString *)parentTablename
                       childTablename:(NSString *)childTableName
                               fromDB:(sqlite3*)db
{
    NSMutableArray *relations = [NSMutableArray array];
    NSString *queryRelation;
    if (parentId < 0) {
        queryRelation = [NSString stringWithFormat:@"select child_id from %@_%@",parentTablename,childTableName];
    }else{
        queryRelation = [NSString stringWithFormat:@"select child_id from %@_%@ where parent_id = %ld",parentTablename,childTableName,(long)parentId];
    }
    
    NSInteger refPk = 0;
    sqlite3_stmt *refStmt;
    if (sqlite3_prepare_v2(db, [queryRelation UTF8String], -1, &refStmt, nil) == SQLITE_OK) {
        while (sqlite3_step(refStmt) == SQLITE_ROW) {
            refPk =sqlite3_column_int(refStmt, 0);
            [relations addObject:[NSNumber numberWithInteger:refPk]];
        }
    }
    
    sqlite3_finalize(refStmt);
    return relations;
}

+ (NSArray *)queryByPks:(NSArray *)pks
{
    if (!pks || pks.count <= 0) {
        return nil;
    }
    NSMutableArray *models = [NSMutableArray array];

    [self buildAndCheckMeta];
    sqlite3 *db = [DPDBManager database];
    DBMETA *meta = [[[DPDBManager singleton] metaInfos] objectForKey:NSStringFromClass([self class])];
    NSString *query;
    NSInteger pk;
    for (long i = 0, len = pks.count; i < len; i++) {
        pk = [pks[i] integerValue];
        query = [meta.query stringByAppendingFormat:@" where pk = %ld",(long)pk];
        [models addObjectsFromArray:[self doInternalQuery:query database:db classMeta:meta]];
    }
    
    return models;
}

+ (NSArray *)allObjects
{
    [self buildAndCheckMeta];
    NSArray *result;
    sqlite3 *db = [DPDBManager database];
    DBMETA *meta = [[[DPDBManager singleton] metaInfos] objectForKey:NSStringFromClass([self class])];
    NSString *query = meta.query;

    result = [self doInternalQuery:query database:db classMeta:meta];
    return result;
}

+ (void)deleteAll
{
    [self buildAndCheckMeta];
    char *errmsg = NULL;
    int result ;
    sqlite3 *db = [DPDBManager database];
    DBMETA *meta = [[[DPDBManager singleton] metaInfos] objectForKey:NSStringFromClass([self class])];
    
    
    [self deleteRelationsByParentId:-1 meta:meta fromDB:db];
    
    if ((result = sqlite3_exec(db, [meta.del UTF8String], NULL, NULL, &errmsg))!=SQLITE_OK) {
        NSLog(@"删除全部失败");
    }else{
        NSLog(@"删除全部成功");
    }
}

+ (void)deleteByPks:(NSArray *)pks
{
    [self buildAndCheckMeta];
    sqlite3 *db = [DPDBManager database];
    DBMETA *meta = [[[DPDBManager singleton] metaInfos] objectForKey:NSStringFromClass([self class])];
    for (NSNumber *pk in pks) {
        [self doInternalDeleteByPk:[pk integerValue] meta:meta fromDB:db];
    }
}

+ (void)saveObjects:(NSArray *)models
{
    [self buildAndCheckMeta];
    sqlite3 *db = [DPDBManager database];
    DBMETA *meta = [[[DPDBManager singleton] metaInfos] objectForKey:NSStringFromClass([self class])];
    for (id model in models) {
        [self doInternalSave:model database:db classMeta:meta];
    }
}

+ (void)doInternalSave:(DPDBObject *)model database:(sqlite3 *)db classMeta:(DBMETA*)meta
{
    sqlite3_stmt *stmt;
    NSError *err;
    NSInteger pk = [model pk];
    if (pk < 0) {
        pk = [DPDBManager seqWithClazz:meta.tablename];
        [model setPK:pk];
        if (sqlite3_prepare_v2(db, [meta.insert UTF8String], -1, &stmt, nil) == SQLITE_OK) {
            NSString *type;
            NSString *name;
            DBMETAPROP *prop;
            NSArray *properties = meta.props;
            int position = 1;
            sqlite3_bind_int64(stmt, position++, pk);
            for (long i=0,len=properties.count; i<len; i++) {
                prop = properties[i];
                name = prop.propName;
                type = prop.dbtype;
                if (!prop.transient) {
                    if (type != nil) {
                        if ([[type lowercaseString] isEqualToString:@"integer"]) {
                            sqlite3_bind_int(stmt, position, [[model valueForKey:name] intValue]);
                        }else if([[type lowercaseString]isEqualToString:@"double"]
                                 || [[type lowercaseString] isEqualToString:@"float"]
                                 || [[type lowercaseString]isEqualToString:@"real"]){
                            sqlite3_bind_double(stmt, position, [[model valueForKey:name] doubleValue]);
                        }else if([[type lowercaseString] isEqualToString:@"text"]){
                            sqlite3_bind_text(stmt, position, [[model valueForKey:name] UTF8String], -1, NULL);
                        }
                        else{
                            NSLog(@"%@ 类型暂未实现",type);
                        }
                        position ++;
                    }
                }else{
                    
                    //NSLog(@"暂时未实现集合和对象类型");
                    if (isCollectionType(prop.obType)) {
                        if (!isNSDictionaryType(prop.obType)) {
                            //集合不为空
                            NSArray *refModels = [model valueForKey:name];
                            if(refModels!=nil && refModels.count > 0){
                                DPDBObject *m = refModels[0];
                                if ([m isKindOfClass:[DPDBObject class]]) {
                                    [[m class] saveObjects:refModels];
                                    NSString *childTableName = NSStringFromClass([m class]);
                                    for (DPDBObject *model in refModels) {
                                        [self createRelationWithParentId:pk parentTablename:meta.tablename relationId:[model pk] relationTablename:childTableName toDB:db];
                                    }
                                    if (prop.obInternalType==nil) {
                                        prop.obInternalType = childTableName;
                                    }
                                }
                            }
                        }
                        
                    }else if ([NSClassFromString(prop.obType) isSubclassOfClass:[DPDBObject class]]){
                        DPDBObject *subModel = [model valueForKey:prop.propName];
                        if (subModel) {
                            //先保存关系
                            //@"create table if not exists %@_%@ (pk integer  auto_increment primary key, parent_id integer, child_id integer)"
                            //再保存对象
                            [subModel save];
                            NSInteger refSeq = [subModel pk];
                            [self createRelationWithParentId:pk parentTablename:meta.tablename relationId:refSeq relationTablename:prop.obType toDB:db];
                        }
                    }
                }
            }
            if (sqlite3_step(stmt) != SQLITE_DONE) {
                err = [NSError errorWithDomain:kDPDBErrorDomain code:kDPDBInsertDataBindError userInfo:@{@"error":@"SQL绑定数据错误，请检查"}];
            }
            sqlite3_finalize(stmt);
        }else{
            err = [NSError errorWithDomain:kDPDBErrorDomain code:kDPDBInsertSQLError userInfo:@{@"error":[NSString stringWithFormat: @"插入语句 <%@> 错误，请检查",meta.insert]}];
        }
    }else{
        
    }
}

+ (void)createRelationWithParentId:(NSInteger)parentId
                   parentTablename:(NSString *)parentTablename
                        relationId:(NSInteger)relationId
                 relationTablename:(NSString *)relationTablename
                              toDB:(sqlite3 *)db
{
    char *errmsg = NULL;
    int result ;
    NSString *insertRelation = [NSString stringWithFormat:@"insert into %@_%@ (parent_id,child_id) values(%ld,%ld)",parentTablename,relationTablename,(long)parentId,(long)relationId];
    if ((result = sqlite3_exec(db, [insertRelation UTF8String], NULL, NULL, &errmsg))!=SQLITE_OK) {
        NSLog(@"更新关系失败 : %@_%@  errorCode : %d",parentTablename,relationTablename,result);
    }else{
        NSLog(@"更新关系成功表: %@_%@ ",parentTablename,relationTablename);
    }
}

+ (NSDictionary *)classPropertiesWithType
{
    unsigned int outCount;
    NSMutableDictionary *propsDic = [NSMutableDictionary dictionary];
    
    objc_property_t *props = class_copyPropertyList([self class], &outCount);
    
    for (int i = 0; i < outCount; i++) {
        objc_property_t aProp = props[i];
        
        //获得属性名称
        NSString *propName = [NSString stringWithUTF8String:property_getName(aProp)];
        NSString *propAttr = [NSString stringWithUTF8String:property_getAttributes(aProp)];
        
        //只读属性不可修改
        //如果为可修改属性，设置property的属性类型
        if ([propAttr rangeOfString:@",R,"].location == NSNotFound)
        {
            NSArray *attrParts = [propAttr componentsSeparatedByString:@","];
            if (attrParts != nil)
            {
                if ([attrParts count] > 0)
                {
                    NSString *propType = [[attrParts objectAtIndex:0] substringFromIndex:1];
                    [propsDic setObject:propType forKey:propName];
                }
            }
        }
    }
    free(props);
    
    return propsDic;
}

+ (void)syncSeq:(NSInteger)seq
{
    [self  buildAndCheckMeta];
    sqlite3 *db = [DPDBManager database];
    
    char *errmsg = NULL;
    NSString *pkIncSQL = [NSString stringWithFormat:@"UPDATE PKSEQ SET SEQ=%ld WHERE NAME='%@'",(long)seq,NSStringFromClass([self class])];
    if (sqlite3_exec(db, [pkIncSQL UTF8String], NULL, NULL, &errmsg)) {
        NSLog(@"增加%@的主键失败!",NSStringFromClass([self class]));
    }
    
    sqlite3_free(errmsg);
}

+ (void)buildAndCheckMeta
{
    [[self class] buildMeta];
    DBMETA *meta = [[[DPDBManager singleton] metaInfos] objectForKey:NSStringFromClass([self class])];
    if (!meta.buildRelation) {
        [[[self class] alloc] init];
    }
}


//查询当前类的序列号
+ (NSInteger)currentSeq
{
    [self buildAndCheckMeta];
    NSInteger pk = 1;
    sqlite3 *db = [DPDBManager database];
    sqlite3_stmt *stmt;
    
    NSMutableString *query = [NSMutableString stringWithFormat:@"SELECT max(pk) from '%@'",NSStringFromClass([self class])];
    if (sqlite3_prepare_v2(db, [query UTF8String], -1, &stmt, nil) == SQLITE_OK) {
        if (sqlite3_step(stmt) == SQLITE_ROW) {
            pk = sqlite3_column_int(stmt, 0) + 1;
        }
        sqlite3_finalize(stmt);
    }
    return pk;
}


@end
