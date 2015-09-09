//
//  DPDBObject.h
//  DoPersistenceFramework
//
//  Created by Ju on 14/10/27.
//  Copyright (c) 2014年 scics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSArray+DPModelExtention.h"
#import "NSSet+DPModelExtention.h"

#define isCollectionType(x) (isNSSetType(x) || isNSArrayType(x) || isNSDictionaryType(x))
#define isNSArrayType(x) ([x isEqualToString:@"NSArray"] || [x isEqualToString:@"NSMutableArray"])
#define isNSDictionaryType(x) ([x isEqualToString:@"NSDictionary"] || [x isEqualToString:@"NSMutableDictionary"])
#define isNSSetType(x) ([x isEqualToString:@"NSSet"] || [x isEqualToString:@"NSMutableSet"])
#define isNSStringType(x) ([x isEqualToString:@"NSString"] || [x isEqualToString:@"NSMutableString"])

@interface DPDBObject : NSObject

/**
 *  保存，把对象信息保存数据库
 */
- (void)save;

/**
 *  删除对象，从数据库中删除本对象，删除后pk为-1
 */
- (void)deleteMe;

/**
 *  主键值
 *
 *  @return 主键值
 */
- (NSInteger)pk;


//用于一对多关系的对象保存时提供集合类型保存的对象类型
/**
 *  在对象中包含集合类型时，需要把里面元素是何种对象类型的信息返回
 *  example:
 *  return @{
 *       @{@"propertyName":@"Person"}
 *  }
 *  表示类中有个集合类型的属性叫"propertyName"，它里面装得元素类型为"Person"
 *
 *  @return 集合属性的元素对象类型信息
 */
+ (NSDictionary *)collectionTypeInfo;

/**
 *  批量保存对象，要求里面的对象类型是和本对象类型一致
 *
 *  @param models 对象数组
 */
+ (void)saveObjects:(NSArray *)models;

/**
 *  根据主键pk值，查找对象
 *
 *  @param pk 主键值
 *
 *  @return 查找到的对象，如果没有找到则返回nil
 */
+ (DPDBObject *)queryByPk:(NSInteger)pk;

/*!
 @param criteriaString 条件语句
 
 @return 查找到的对象，如果没有找到则返回nil
 
 @description 根据条件查找对象，例如 "name like 'abc'"，注意不需要加 where
 
*/
+ (NSArray *)findByCriteria:(NSString *)criteriaString;

/*!
 @param criteriaString 条件语句
 @param page 第几页 从1开始
 @param pageLimit 每页数量
 
 @return 查找到的对象，如果没有找到则返回nil
 
 @description 根据条件查找对象，例如 "name like 'abc'"，注意不需要加 where
 
*/
+ (NSArray *)findByCriteria:(NSString *)criteriaString
                       page:(NSInteger)page
                  pageLimit:(NSInteger)pageLimit;

/**
 *  查询所有对象
 *
 *  @return 查询结果数组
 */
+ (NSArray *)allObjects;

/*!
 @param page 第几页 从1开始
 @param pageLimit 每页数量
 
 @return 查找到的对象，如果没有找到则返回nil
 
 @description 分页查询对象
 
 */
+ (NSArray *)objectsWithPage:(NSInteger)page pageLimit:(NSInteger)pageLimit;

/**
 *  删除对象对应表中所有数据
 */
+ (void)deleteAll;

/**
 *  根据主键数组删除数据库中的记录
 *
 *  @param pks 主键数组
 */
+ (void)deleteByPks:(NSArray *)pks;

/**
 *  同步该表主键值到数据库
 *
 *  @param seq 序列值
 */
+ (void)syncSeq:(NSInteger)seq;

/**
 *  现在的主键序列值，即目前最大的主键值
 *
 *  @return 序列值
 */
+ (NSInteger)currentSeq;

@end
