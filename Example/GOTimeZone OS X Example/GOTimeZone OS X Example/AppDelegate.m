//
//  AppDelegate.m
//  GOTimeZone OS X Example
//
//  Created by Henri Normak on 26/03/2014.
//  Copyright (c) 2014 Henri Normak. All rights reserved.
//

#import "AppDelegate.h"
#import "GOTimeZone.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Fetch timezone for Tallinn, Estonia
    CLLocation *tallinn = [[CLLocation alloc] initWithLatitude:59.43696079999999 longitude:24.7535746];
    GOTimeZone *timezone = [[GOTimeZone alloc] init];
    [timezone requestTimezoneForLocation:tallinn completionHandler:^(NSTimeZone *timezone, NSError *error) {
        if (timezone)
            NSLog(@"Timezone for Tallinn, Estonia => %@", timezone);
        else
            NSLog(@"Error occured when getting timezone for Tallinn, Estonia => %@", error.localizedDescription);
    }];
}

@end
