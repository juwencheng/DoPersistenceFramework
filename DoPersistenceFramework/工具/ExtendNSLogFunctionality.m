//
//  ExtendNSLogFunctionality.m
//  MobileGuide
//
//  Created by 鞠 文杰 on 13-11-25.
//  Copyright (c) 2013年 CSICS. All rights reserved.
//

#import "ExtendNSLogFunctionality.h"

@implementation ExtendNSLogFunctionality

void ExtendNSLog(const char *file, int lineNumber, const char *functionName, NSString *format, ...)
{

    // Type to hold information about variable arguments.
    va_list ap;
    
    // Initialize a variable argument list.
    va_start (ap, format);
    
    // NSLog only adds a newline to the end of the NSLog format if
    // one is not already there.
    // Here we are utilizing this feature of NSLog()
    if (![format hasSuffix: @"\n"])
    {
        format = [format stringByAppendingString: @"\n"];
    }
    
    NSString *body = [[NSString alloc] initWithFormat:format arguments:ap];
    
    // End using variable argument list.
    va_end (ap);
    
//    NSString *fileName = [[NSString stringWithUTF8String:file] lastPathComponent];
//    fprintf(stderr, "『 %s 』 (%s:%d) \n 输出信息 : %s",
//            [fileName UTF8String],
//            functionName,
//            lineNumber, [body UTF8String]);
    fprintf(stderr, "『 %s 』 行数: %d \n 输出信息 : %s",
            functionName,
            lineNumber, [body UTF8String]);
}

@end
