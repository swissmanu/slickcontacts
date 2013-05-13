//
//  MAAppDelegate.m
//  TouchDBDemo
//
//  Created by Manuel Alabor on 08.05.13.
//  Copyright (c) 2013 Manuel Alabor. All rights reserved.
//

#import "MAAppDelegate.h"
#import <TestFlight.h>

@implementation MAAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	#ifdef TESTFLIGHT_TOKEN
	[TestFlight takeOff:TESTFLIGHT_TOKEN];
	#endif
    return YES;
}

@end
