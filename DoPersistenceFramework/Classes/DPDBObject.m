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
    }
    return self;
}

- (NSInteger)pk
{
    return pk;
}

- (void)setPK:(int)thePK
{
    pk = thePK ;
}

- (void)save
{
    sqlite3 *db = [DPDBManager database];
    sqlite3_stmt *stmt;
    NSError *err;
    if (pk < 0) {
        pk = [DPDBManager seqWithClazz:classMeta.tablename];
        NSLog(@"pk : %d",pk);
        if (sqlite3_prepare_v2(db, [classMeta.insert UTF8String], -1, &stmt, nil) == SQLITE_OK) {
            NSString *type;
            NSString *name;
            DBMETAPROP *prop;
            NSArray *properties = classMeta.props;
            int position = 1;
            sqlite3_bind_int(stmt, position++, pk);
            for (int i=0,len=properties.count; i<len; i++) {
                prop = properties[i];
                if (!prop.transient) {
                    name = prop.propName;
                    type = prop.dbtype;
                    if (type != nil) {
                        if ([[type lowercaseString] isEqualToString:@"integer"]) {
                            sqlite3_bind_int(stmt, position, [[self valueForKey:name] intValue]);
                        }else if([[type lowercaseString]isEqualToString:@"double"]
                                 || [[type lowercaseString] isEqualToString:@"float"]
                                 || [[type lowercaseString]isEqualToString:@"real"]){
                            sqlite3_bind_double(stmt, position, [[self valueForKey:name] doubleValue]);
                        }else if([[type lowercaseString] isEqualToString:@"text"]){
                            sqlite3_bind_text(stmt, position, [[self valueForKey:name] UTF8String], -1, NULL);
                        }
                        else{
                            NSLog(@"%@ 类型暂未实现",type);
                        }
                        position ++;
                    }
                }else{
                    
//                    NSLog(@"暂时未实现集合和对象类型");
                    if (isCollectionType(prop.obType)) {
                        NSLog(@"集合类型");
                        //集合不为空
                        if([self valueForKey:name]!=nil){
                            
                        }
                    }else if ([NSClassFromString(prop.obType) isSubclassOfClass:[DPDBObject class]]){
                        DPDBObject *model = [self valueForKey:prop.propName];
                        if (model) {
                            //先保存关系
                            //@"create table if not exists %@_%@ (pk integer  auto_increment primary key, parent_id integer, child_id integer)"
                            //再保存对象
                            [model save];
                            NSInteger refSeq = [model pk];
                            char *errmsg = NULL;
                            int result ;
                            NSString *updateRelation = [NSString stringWithFormat:@"insert into %@_%@(parent_id,child_id) values(%d,%d)",classMeta.tablename,prop.obType,pk,refSeq];
                            if ((result = sqlite3_exec(db, [updateRelation UTF8String], NULL, NULL, &errmsg))!=SQLITE_OK) {
                                NSLog(@"更新关系失败 : %@_%@  errorCode : %d",classMeta.tablename,prop.obType,result);
                            }else{
                                NSLog(@"更新关系成功表: %@_%@ ",classMeta.tablename,prop.obType);
                            }
                        }
                    }
                }
                
            }
            if (sqlite3_step(stmt) != SQLITE_DONE) {
                err = [NSError errorWithDomain:kDPDBErrorDomain code:kDPDBInsertDataBindError userInfo:@{@"error":@"SQL绑定数据错误，请检查"}];
            }
            sqlite3_finalize(stmt);
        }else{
            err = [NSError errorWithDomain:kDPDBErrorDomain code:kDPDBInsertSQLError userInfo:@{@"error":[NSString stringWithFormat: @"插入语句 <%@> 错误，请检查",classMeta.insert]}];
        }
    }else{
        
    }
}



- (NSError *)deleteMe
{
    if (pk<0) {
        return nil;
    }
    //关联删除
    sqlite3 *db = [DPDBManager database];
    NSString *deleteSql = [NSString stringWithFormat:@"%@ WHERE pk = ?",classMeta.del];
    
    sqlite3_stmt *stmt;
    NSError *error;
    if (sqlite3_prepare_v2(db, [deleteSql UTF8String], -1, &stmt, nil) == SQLITE_OK) {
        sqlite3_bind_int(stmt, 1, pk);
        if (sqlite3_step(stmt)!=SQLITE_DONE) {
            error = [NSError errorWithDomain:@"com.jackdono" code:kDPDBDeleteError userInfo:@{@"error":[NSString stringWithFormat:@"删除错误 <%@>",deleteSql]}];
        }
    }else{
        //sql error
        error = [NSError errorWithDomain:@"com.jackdono" code:kDPDBDeleteSQLError userInfo:@{@"error":[NSString stringWithFormat:@"删除语法错误 <%@>",deleteSql]}];
    }
    
    sqlite3_finalize(stmt);
    return error;
}

//核心是遍历
//构建tableview的元信息
+ (void)buildMeta
{
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
            if(![pMeta.obType isEqualToString:@"ARRAY"]
               &&![pMeta.obType isEqualToString:@"SET"]){
                Class clazz = NSClassFromString(pMeta.obType);
                if ([clazz isSubclassOfClass:[DPDBObject class]]) {
                    //一对一关系
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
                }
            }
        }
    }
    meta.insert = [NSString stringWithFormat:@"insert into %@ (pk,%@ ) values (? ,%@ )",meta.tablename,[ins substringToIndex:(ins.length-1)],[ins_1 substringToIndex:(ins_1.length-1)]];
    meta.create = [NSString stringWithFormat:@"create table if not exists %@ (pk integer primary key , %@ )",meta.tablename,[create substringToIndex:create.length-1]];
    meta.update = [NSString stringWithFormat:@"update %@ %@ where pk = ?",meta.tablename,[update substringToIndex:update.length-1]];
    meta.query = [NSString stringWithFormat:@"select pk , %@ from %@",[ins substringToIndex:(ins.length-1)],meta.tablename];
    
    [[[DPDBManager singleton] metaInfos] setObject:meta forKey:meta.tablename];
    
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
}

+ (DPDBObject *)queryByPk:(NSInteger)pk
{
    if (pk<0) {
        return nil;
    }
    id model ;
    
    [self buildMeta];
    sqlite3 *db = [DPDBManager database];
    DBMETA *meta = [[[DPDBManager singleton] metaInfos] objectForKey:NSStringFromClass([self class])];
    
    NSString *query = [meta.query stringByAppendingFormat:@" where pk = %d",pk];
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
            DBMETAPROP *prop ;
            //            [model setValue:[NSNumber numberWithInt:sqlite3_column_int(stmt, position++)] forKey:@"pk"];
            NSInteger thePk =sqlite3_column_int(stmt, position++);
            [model setPK:thePk];
            for (int i=0,len=props.count; i<len; i++) {
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
                        
                    }else if([NSClassFromString(prop.obType) isSubclassOfClass:[DPDBObject class]]){
                        NSString *queryRelation = [NSString stringWithFormat:@"select child_id from %@_%@ where parent_id = %d",meta.tablename,prop.obType,thePk];
                        NSInteger refPk = 0;
                        sqlite3_stmt *refStmt;
                        if (sqlite3_prepare_v2(db, [queryRelation UTF8String], -1, &refStmt, nil) == SQLITE_OK) {
                            while (sqlite3_step(refStmt) == SQLITE_ROW) {
                                refPk =sqlite3_column_int(refStmt, 0);
                            }
                        }
                        //直接忽略查出多条数据的情况
                        if (refPk != 0) {
                            id refModel = [NSClassFromString(prop.obType) queryByPk:refPk];
                            [model setValue:refModel forKey:prop.propName];
                        }
                        sqlite3_finalize(refStmt);
                    }
                }
               
            }
            [result addObject:model];
        }
    }
    sqlite3_finalize(stmt);
    return result;
}

+ (NSArray *)queryByPks:(NSArray *)pks
{
    if (!pks || pks.count <= 0) {
        return nil;
    }
    NSMutableArray *models = [NSMutableArray array];

    [self buildMeta];
    sqlite3 *db = [DPDBManager database];
    DBMETA *meta = [[[DPDBManager singleton] metaInfos] objectForKey:NSStringFromClass([self class])];
//    sqlite3_stmt *stmt;
    NSString *query;
    NSInteger pk;
    for (int i = 0, len = pks.count; i < len; i++) {
        pk = [pks[i] integerValue];
        query = [meta.query stringByAppendingFormat:@" where pk = %d",pk];
//        NSArray *props = meta.props;
        [models addObjectsFromArray:[self doInternalQuery:query database:db classMeta:meta]];
//        if (sqlite3_prepare_v2(db, [query UTF8String], -1, &stmt, nil) == SQLITE_OK) {
//            id model;
//            while (sqlite3_step(stmt) == SQLITE_ROW) {
//                model = [[[self class] alloc] init];
//                NSString *type;
//                NSString *name;
//                int position = 0;
//                DBMETAPROP *prop ;
//                //            [model setValue:[NSNumber numberWithInt:sqlite3_column_int(stmt, position++)] forKey:@"pk"];
//                NSInteger thePk =sqlite3_column_int(stmt, position++);
//                [model setPK:thePk];
//                for (int i=0,len=props.count; i<len; i++) {
//                    prop = props[i];
//                    name = prop.propName;
//                    type = prop.dbtype;
//                    if (!prop.transient) {
//                        if (type != nil) {
//                            if ([[type lowercaseString] isEqualToString:@"integer"]
//                                || [[type lowercaseString] isEqualToString:@"double"]
//                                || [[type lowercaseString ] isEqualToString:@"float"]
//                                || [[type lowercaseString] isEqualToString:@"real"]) {
//                                [model setValue:[NSNumber numberWithInt: sqlite3_column_int(stmt, position)] forKey:name];
//                            }else if([[type lowercaseString] isEqualToString:@"text"]){
//                                const char *columnValue =(char *) sqlite3_column_text(stmt, position);
//                                columnValue = (columnValue == NULL)?"":columnValue;
//                                [model setValue:[NSString stringWithUTF8String:columnValue] forKey:name];
//                            }
//                            else{
//                                NSLog(@"%@ 类型暂未实现",type);
//                            }
//                            position ++;
//                        }
//                    }else{
//                        if (isCollectionType(prop.obType)) {
//                            
//                        }else if([NSClassFromString(prop.obType) isSubclassOfClass:[DPDBObject class]]){
//                            
//                        }
//                    }
//                    [models addObject:model];
//                    
//                }
//                
//            }
//            sqlite3_finalize(stmt);
//        }
    }
    
    
    return models;
}

+ (NSArray *)allObjects
{
    [self buildMeta];
//    NSMutableArray *result = [NSMutableArray array];
    NSArray *result;
    sqlite3 *db = [DPDBManager database];
    DBMETA *meta = [[[DPDBManager singleton] metaInfos] objectForKey:NSStringFromClass([self class])];
//    sqlite3_stmt *stmt;
    NSString *query = meta.query;
//    NSArray *props = meta.props;
//    if (sqlite3_prepare_v2(db, [query UTF8String], -1, &stmt, nil) == SQLITE_OK) {
//        id model;
//        while (sqlite3_step(stmt) == SQLITE_ROW) {
//            model = [[[self class] alloc] init];
//            NSString *type;
//            NSString *name;
//            int position = 0;
//            DBMETAPROP *prop ;
//            //            [model setValue:[NSNumber numberWithInt:sqlite3_column_int(stmt, position++)] forKey:@"pk"];
//            NSInteger thePk =sqlite3_column_int(stmt, position++);
//            [model setPK:thePk];
//            for (int i=0,len=props.count; i<len; i++) {
//                prop = props[i];
//                name = prop.propName;
//                type = prop.dbtype;
//                if (!prop.transient) {
//                    if (type != nil) {
//                        if ([[type lowercaseString] isEqualToString:@"integer"]
//                            || [[type lowercaseString] isEqualToString:@"double"]
//                            || [[type lowercaseString ] isEqualToString:@"float"]
//                            || [[type lowercaseString] isEqualToString:@"real"]) {
//                            [model setValue:[NSNumber numberWithInt: sqlite3_column_int(stmt, position)] forKey:name];
//                        }else if([[type lowercaseString] isEqualToString:@"text"]){
//                            const char *columnValue =(char *) sqlite3_column_text(stmt, position);
//                            columnValue = (columnValue == NULL)?"":columnValue;
//                            [model setValue:[NSString stringWithUTF8String:columnValue] forKey:name];
//                        }
//                        else{
//                            NSLog(@"%@ 类型暂未实现",type);
//                        }
//                        position ++;
//                    }
//                }else{
//                    if (isCollectionType(prop.obType)) {
//                        
//                    }else if([NSClassFromString(prop.obType) isSubclassOfClass:[DPDBObject class]]){
//                        
//                    }
//                }
//                
//                
//            }
////            [model addPropertiesObserver];
//            [result addObject:model];
//        }
//    }
    result = [self doInternalQuery:query database:db classMeta:meta];
//    sqlite3_finalize(stmt);
    return result;
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
    [[self class] buildMeta];
    sqlite3 *db = [DPDBManager database];
    
    char *errmsg = NULL;
    NSString *pkIncSQL = [NSString stringWithFormat:@"UPDATE PKSEQ SET SEQ=%d WHERE NAME='%@'",seq,NSStringFromClass([self class])];
    if (sqlite3_exec(db, [pkIncSQL UTF8String], NULL, NULL, &errmsg)) {
        NSLog(@"增加%@的主键失败!",NSStringFromClass([self class]));
    }
    
    sqlite3_free(errmsg);
}


//查询当前类的序列号
+ (NSInteger)currentSeq
{
    [self buildMeta];
    NSInteger pk = 1;
    sqlite3 *db = [DPDBManager database];
    sqlite3_stmt *stmt;
    
//    @"SELECT SEQ FROM PKSEQ WHERE NAME = '%@'"
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
