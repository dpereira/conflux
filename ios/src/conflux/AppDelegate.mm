
#import "Mouse.h"
#import "AppDelegate.h"
#import "Point.h"
#import "TouchpadViewController.h"
    
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
    UINavigationController * navigationController = (UINavigationController*)application.keyWindow.rootViewController;
    UIView * current = navigationController.visibleViewController.view;
    CFXPoint* sourceResolution = [[CFXPoint alloc] initWith:current.bounds.size.width
                                                        andWith:current.bounds.size.height];
    [self._synergy load:sourceResolution];
    
    [(TouchpadViewController*)current.nextResponder resetScreens];

    application.idleTimerDisabled = YES;
}

- (void) applicationWillResignActive:(UIApplication *)application
{
    application.idleTimerDisabled = NO;
    [self._synergy unload];
}

- (void) applicationWillTerminate:(UIApplication *)application
{
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
   
    self._synergy = [[CFXSynergy alloc] init];
    
    return YES;
}

- (void) _orientationChanged:(NSNotification*) note
{
    [self._synergy changeOrientation];
}

@end
