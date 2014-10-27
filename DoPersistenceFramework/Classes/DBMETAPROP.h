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

@property (nonatomic) BOOL transient;
@property (nonatomic,strong) NSString *propName;
//对应的数据库类型
@property (nonatomic,strong) NSString *dbtype;
//对应的对象类型
@property (nonatomic,strong) NSString *obType;

@end
