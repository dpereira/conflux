
#import "Mouse.h"
#import "AppDelegate.h"
#import "Point.h"
    
@interface AppDelegate ()

@end

@implementation AppDelegate

- (id)init
{
    if(self = [super init]) {
        return self;
    } else {
        return nil;
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"APPLICATION ACTIVE");

    UINavigationController * navigationController = (UINavigationController*)application.keyWindow.rootViewController;
    UIView * current = navigationController.visibleViewController.view;
    CFXPoint* sourceResolution = [[CFXPoint alloc] initWith:current.bounds.size.width
                                                        andWith:current.bounds.size.height];
    [self._synergy load:sourceResolution];

    application.idleTimerDisabled = YES;
    NSLog(@"Became active");
}

- (void) applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"Will resign");
    application.idleTimerDisabled = NO;
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
   
    NSLog(@"Finish launching");
    self._synergy = [[CFXSynergy alloc] init];
    NSLog(@"DONE Finish launching");
    
    return YES;
}

- (void) _orientationChanged:(NSNotification*) note
{
    [self._synergy changeOrientation];
}

@end
