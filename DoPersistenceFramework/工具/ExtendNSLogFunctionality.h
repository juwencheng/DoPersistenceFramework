//
//  ExtendNSLogFunctionality.h
//  MobileGuide
//
//  Created by 鞠 文杰 on 13-11-25.
//  Copyright (c) 2013年 CSICS. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef DEBUG

#define NSLog(args...) ExtendNSLog(__FILE__,__LINE__,__PRETTY_FUNCTION__,args)

//#else
//
//#define NSLog(x...)

#endif

void
ExtendNSLog(const char *file, int lineNumber, const char *functionName, NSString *format, ...);

@interface ExtendNSLogFunctionality : NSObject

@end
