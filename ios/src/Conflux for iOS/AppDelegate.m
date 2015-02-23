//
//  AppDelegate.m
//  Conflux for iOS
//
//  Created by Diego Pereira on 1/22/15.
//  Copyright (c) 2015 Conflux. All rights reserved.
//

#import "AppDelegate.h"
#include "synergy/Synergy.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application withOptions:(NSDictionary *)launchOptions{
    return YES;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touched = [[event allTouches] anyObject];
    CGPoint location = [touched locationInView:touched.view];
    [self.synergy mouseMove: location.x withY: location.y];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *aTouch in touches) {
        if (aTouch.tapCount >= 2) {
            [self.synergy doubleClick: 1];
        }
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    self.synergy = [Synergy new];
}

@end
