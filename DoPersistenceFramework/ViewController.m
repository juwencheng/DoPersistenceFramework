
//  ViewController.m
//  DoPersistenceFramework
//
//  Created by Ju on 14/10/27.
//  Copyright (c) 2014年 scics. All rights reserved.
//

#import "ViewController.h"
#import "Test1.h"
#import "Test.h"
#import "Obj1.h"
#import "Obj2.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    NSLog(@"%@",[self testCurrentThread]);
//    [self createObject];
//    [self deleteObjects];
    for (int i = 0; i < 20; i++) {
        [NSThread detachNewThreadSelector:@selector(createObject) toTarget:self withObject:nil];
        [NSThread detachNewThreadSelector:@selector(deleteObjects) toTarget:self withObject:nil];
    }
}

- (NSArray *)testCurrentThread {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    dispatch_queue_t queue = dispatch_queue_create(DISPATCH_QUEUE_PRIORITY_DEFAULT, DISPATCH_QUEUE_SERIAL);
    __block NSArray *result;
    dispatch_async(queue, ^{
        result  = @[@1];
        dispatch_semaphore_signal(semaphore);
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return result;
}

- (void)createObject {
    Test1 *test1 = [[Test1 alloc] init];
    test1.name = @"test";
    Test *test = [[Test alloc] init];
    test.t1 = test1;
    [test save];
}

- (void)deleteObjects {
    [Test1 deleteAll];
}

- (void)findObjects {
    [Test1 allObjects];
}

@end
