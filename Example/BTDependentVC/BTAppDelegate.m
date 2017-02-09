//
//  BTAppDelegate.m
//  BTDependentVC
//
//  Created by Денис Либит on 02/07/2017.
//  Copyright (c) 2017 Денис Либит. All rights reserved.
//

#import "BTAppDelegate.h"
#import "BTRootVC.h"


@implementation BTAppDelegate

//
// -----------------------------------------------------------------------------
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.window.backgroundColor = [UIColor whiteColor];
	self.window.rootViewController = [[BTRootVC alloc] init];
	[self.window makeKeyAndVisible];
	return YES;
}

@end
