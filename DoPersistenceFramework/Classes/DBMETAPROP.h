//
//  DBMETAPROP.h
//  DoPersistenceFramework
//
//  Created by Ju on 14/10/27.
//  Copyright (c) 2014年 scics. All rights reserved.
//

#import <Foundation/Foundation.h>

//属性的类
@interface DBMETAPROP : NSObject

//属性是否为对象类型
@property (nonatomic,assign) BOOL isObjectType;

//属性的名字
@property (nonatomic,strong) NSString *propName;

//属性对应的数据库类型
@property (nonatomic,strong) NSString *dbtype;

//对应的对象类型
@property (nonatomic,strong) NSString *obType;

//用于记录集合类型里面对象的实际类型，只有当此属性为集合类型时才有意义
@property (nonatomic,strong) NSString *obInternalType;

@end
