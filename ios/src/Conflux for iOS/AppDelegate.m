//
//  AppDelegate.m
//  Conflux for iOS
//
//  Created by Diego Pereira on 1/22/15.
//  Copyright (c) 2015 Conflux. All rights reserved.
//

#import "AppDelegate.h"
#import "synergy/Synergy.h"
#import "Point.h"
#import "Mouse.h"

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
    CFXPoint* p = [[CFXPoint alloc] initWith:location.x and:location.y];
    [self.synergy mouseMove: p];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *aTouch in touches) {
        if (aTouch.tapCount >= 2) {
            [self.synergy doubleClick: Right];
        } else if(aTouch.tapCount == 1) {
            [self.synergy click: Right];
        }
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    self.synergy = [Synergy new];
}

- (BOOL)application:(UIApplication*)application
        didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    UIDevice *device = [UIDevice currentDevice];
    [device beginGeneratingDeviceOrientationNotifications];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver:self
           selector:@selector(_orientationChanged:)
               name:UIDeviceOrientationDidChangeNotification
             object:device];
    
    return YES;
}

- (void) _orientationChanged:(NSNotification*) note {
    [self.synergy changeOrientation];
}

@end
