//
//  NSSet+DPModelExtention.m
//  DoPersistenceFramework
//
//  Created by Ju on 14/11/17.
//  Copyright (c) 2014年 scics. All rights reserved.
//

#import "NSSet+DPModelExtention.h"
#import <objc/runtime.h>
static const void *DPModelExtention = "DPModelExtention";
@implementation NSSet (DPModelExtention)

@dynamic DPInternalClazz;

- (NSString *)DPInternalClazz
{
    return objc_getAssociatedObject(self, DPModelExtention);
}

- (void)setDPInternalClazz:(NSString *)DPInternalClazz
{
    objc_setAssociatedObject(self, DPModelExtention, DPInternalClazz, OBJC_ASSOCIATION_ASSIGN);
}
@end
