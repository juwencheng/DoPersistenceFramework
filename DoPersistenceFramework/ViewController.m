//
//  ViewController.m
//  DoPersistenceFramework
//
//  Created by Ju on 14/10/27.
//  Copyright (c) 2014年 scics. All rights reserved.
//

#import "ViewController.h"
#import "Test1.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    for (int i = 0; i < 20; i++) {
        [NSThread detachNewThreadSelector:@selector(findObjects) toTarget:self withObject:nil];
    }
    
}

- (void)createObject {
    Test1 *test = [[Test1 alloc] init];
    test.name = @"test";
    [test save];
}

- (void)deleteObjects {
    [Test1 deleteAll];
}

- (void)findObjects {
    [Test1 allObjects];
}

@end
