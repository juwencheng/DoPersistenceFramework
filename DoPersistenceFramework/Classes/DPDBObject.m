//
//  DPDBObject.m
//  DoPersistenceFramework
//
//  Created by Ju on 14/10/27.
//  Copyright (c) 2014年 scics. All rights reserved.
//

#import "DPDBObject.h"
#import <objc/runtime.h>
#import "DBMETA.h"
#import "DBMETAPROP.h"

@implementation DPDBObject


- (instancetype)init
{
    self = [super init];
    if (self) {
        [[self class] buildMeta];
    }
    return self;
}

//核心是遍历
//构建tableview的元信息
+ (void)buildMeta
{
    DBMETA *meta = [[DBMETA alloc] init];
    meta.tablename = NSStringFromClass([self class]);
    
    NSDictionary *d = [self classPropertiesWithType];
    
    //排序
    [d.allKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2 options:NSLiteralSearch];
    }];
    NSLog(@"%@",d);
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
                propmeta.obType = @"ARRAY";
            }else if(isNSSetType(className)){
                propmeta.transient = YES;
                propmeta.obType = @"SET";
            }else if(isNSDictionaryType(className)){
                propmeta.transient = YES;
                propmeta.obType = @"DICTIONARY";
            }else if(isNSStringType(className)){
                propmeta.obType = @"NSSTRING";
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
        }else{
            //创建相应的表格
        }
        
    }
    meta.insert = [NSString stringWithFormat:@"insert into %@ (pk,%@ ) values (? ,%@ )",meta.tablename,[ins substringToIndex:(ins.length-1)],[ins_1 substringToIndex:(ins_1.length-1)]];
    meta.create = [NSString stringWithFormat:@"create table if not exist %@ (pk integer primary key , %@ )",meta.tablename,[create substringToIndex:create.length-1]];
    meta.update = [NSString stringWithFormat:@"update %@ %@",meta.tablename,[update substringToIndex:update.length-1]];
    meta.query = [NSString stringWithFormat:@"select pk , %@ from %@",[ins substringToIndex:(ins.length-1)],meta.tablename];
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


@end
