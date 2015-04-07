#import "TouchpadViewController.h"
#import "AppDelegate.h"

@interface TouchpadViewController ()

@end

@implementation TouchpadViewController

- (void)touchesBegan:(NSSet *)touches
           withEvent:(UIEvent *)event
{

    UITouch *touched = [[event allTouches] anyObject];
    CGPoint location = [touched locationInView:touched.view];
    CFXPoint* p = [[CFXPoint alloc] initWith:location.x and:location.y];
    
    AppDelegate* app = [[UIApplication sharedApplication] delegate];
    [app._synergy beginMouseMove: p];
}

- (void)touchesMoved:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    UITouch *touched = [[event allTouches] anyObject];
    CGPoint location = [touched locationInView:touched.view];
    CFXPoint* p = [[CFXPoint alloc] initWith:location.x and:location.y];
    AppDelegate* app = [[UIApplication sharedApplication] delegate];
    [app._synergy mouseMove: p];
}

- (void)touchesEnded:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    AppDelegate* app = [[UIApplication sharedApplication] delegate];
    
    for (UITouch *aTouch in touches) {
        if (aTouch.tapCount >= 2) {
            [app._synergy doubleClick: kCFXRight];
        } else if(aTouch.tapCount == 1) {
            [app._synergy click: kCFXRight];
        }
    }
}


@end
