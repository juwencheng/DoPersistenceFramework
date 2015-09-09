//
//  DPConstants.h
//  DoPersistenceFramework
//
//  Created by Ju on 14/11/3.
//  Copyright (c) 2014年 scics. All rights reserved.
//

#ifndef DoPersistenceFramework_DPConstants_h
#define DoPersistenceFramework_DPConstants_h

#define sqlDebug  1

static NSString *const kDPDBErrorDomain = @"com.jackdono";

const static NSInteger kDPDBInsertError = 11;
const static NSInteger kDPDBInsertSQLError = 110;
const static NSInteger kDPDBInsertDataBindError = 111;

const static NSInteger kDPDBDeleteError = 12;
const static NSInteger kDPDBDeleteSQLError = 120;
const static NSInteger kDPDBDeleteDataBindError = 121;

const static NSInteger kDPDBUpdateError = 13;
const static NSInteger kDPDBUpdateSQLError = 14;
const static NSInteger kDPDBUpdateDataBindError = 131;

const static NSInteger kPDDBQueryError = 14;
const static NSInteger kPDDBQuerySQLError = 140;
const static NSInteger kPDDBQueryDataBindError = 141;

#endif
