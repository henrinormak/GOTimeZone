//
//  AppDelegate.m
//  GOTimeZone iOS Example
//
//  Created by Henri Normak on 26/03/2014.
//  Copyright (c) 2014 Henri Normak. All rights reserved.
//

#import "AppDelegate.h"
#import "GOTimeZone.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window makeKeyAndVisible];
    
    UIViewController *viewController = [[UIViewController alloc] init];
    self.window.rootViewController = viewController;
    
    // Fetch timezone for Tallinn, Estonia
    CLLocation *tallinn = [[CLLocation alloc] initWithLatitude:59.43696079999999 longitude:24.7535746];
    GOTimeZone *timezone = [[GOTimeZone alloc] init];
    [timezone requestTimezoneForLocation:tallinn completionHandler:^(NSTimeZone *timezone, NSError *error) {
        if (timezone)
            NSLog(@"Timezone for Tallinn, Estonia => %@", timezone);
        else
            NSLog(@"Error occured when getting timezone for Tallinn, Estonia => %@", error.localizedDescription);
    }];
    
    return YES;
}

@end
