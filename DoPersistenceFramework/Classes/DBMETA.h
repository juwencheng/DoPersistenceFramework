//
//  DBAPI.h
//  DoPersistenceFramework
//
//  Created by Ju on 14/10/27.
//  Copyright (c) 2014年 scics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DBMETA : NSObject

@property (nonatomic,strong) NSString *create;
@property (nonatomic,strong) NSString *insert;
@property (nonatomic,strong) NSString *del;
@property (nonatomic,strong) NSString *update;
@property (nonatomic,strong) NSString *query;
@property (nonatomic,strong) NSString *tablename;
@property (nonatomic,strong) NSArray  *props;


@end
