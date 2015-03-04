#import "AppDelegate.h"
#import "synergy/Synergy.h"
#import "Point.h"
#import "Mouse.h"

@interface AppDelegate ()

@property CFXSynergy *_synergy;

@end

@implementation AppDelegate

- (id)init
{
    if(self = [super init]) {
        self._synergy = [CFXSynergy new];
        return self;
    } else {
        return nil;
    }
}

- (BOOL)application:(UIApplication *)application
        withOptions:(NSDictionary *)launchOptions
{
    return YES;
}

- (void)touchesBegan:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    UITouch *touched = [[event allTouches] anyObject];
    CGPoint location = [touched locationInView:touched.view];
    CFXPoint* p = [[CFXPoint alloc] initWith:location.x and:location.y];
    [self._synergy beginMouseMove: p];
}

- (void)touchesMoved:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    UITouch *touched = [[event allTouches] anyObject];
    CGPoint location = [touched locationInView:touched.view];
    CFXPoint* p = [[CFXPoint alloc] initWith:location.x and:location.y];
    [self._synergy mouseMove: p];
}

- (void)touchesEnded:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    for (UITouch *aTouch in touches) {
        if (aTouch.tapCount >= 2) {
            [self._synergy doubleClick: kCFXRight];
        } else if(aTouch.tapCount == 1) {
            [self._synergy click: kCFXRight];
        }
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    UIView * current = application.keyWindow.rootViewController.view;
    CFXPoint* sourceResolution = [[CFXPoint alloc] initWith:current.bounds.size.width
                                                        and:current.bounds.size.height];
    [self ._synergy load:sourceResolution];
}

- (void) applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"Will resign");
    [self._synergy unload];
}

- (void) applicationWillTerminate:(UIApplication *)application
{
    NSLog(@"Will terminate");
    [self._synergy unload];
}

- (BOOL)application:(UIApplication*)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    UIDevice *device = [UIDevice currentDevice];
    [device beginGeneratingDeviceOrientationNotifications];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver:self
           selector:@selector(_orientationChanged:)
               name:UIDeviceOrientationDidChangeNotification
             object:device];
    
    return YES;
}

- (void) _orientationChanged:(NSNotification*) note
{
    [self._synergy changeOrientation];
}

@end
