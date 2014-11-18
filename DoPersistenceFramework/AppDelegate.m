//
//  AppDelegate.m
//  DoPersistenceFramework
//
//  Created by Ju on 14/10/27.
//  Copyright (c) 2014年 scics. All rights reserved.
//

#import "AppDelegate.h"
#import "Test.h"
#import "Test1.h"
#import "NSArray+DPModelExtention.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    
//    [Test1 deleteAll];
    [self addRelationObjects];
    
//    [NSThread sleepForTimeInterval:1];
    
    [Test deleteAll];
    NSLog(@"%d",[Test1 allObjects].count);
//    NSAssert([Test allObjects].count == 0, @"成功");
//    NSAssert([Test1 allObjects].count == 0,@"成功");

//    Test1 *tt1 = tt.t1;
//    NSArray *arr = tt.arr;
//    NSLog(@"%lu",(unsigned long)arr.count);
//    NSLog(@"%lu",(unsigned long)[[Test allObjects] count]);
    return YES;
}

- (void)addRelationObjects
{
    Test *test = [[Test alloc] init];
    
    Test1 *t1 = [[Test1 alloc] init];
    t1.name = @"成功了吗1";
    test.str = @"t1";
    
    Test1 *t2 = [[Test1 alloc] init];
    t2.name = @"成功了吗2";
    
    NSArray *arr = @[t1,t2];
    arr.DPInternalClazz = @"Test1";
    test.arr = arr;
    
    [test save];
    
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
