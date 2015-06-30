#import "TouchpadViewController.h"
#import "AppDelegate.h"
#import <vector>
#import <string>
#import <algorithm>

@interface TouchpadViewController ()

@end

typedef std::vector<std::string> CFXScreenNames;

@implementation TouchpadViewController {
    CFXScreenNames _screenNames;
    CFXSynergy* _synergy;
    int _screenCount;
    std::string _waitingForScreensLabel;
}

- (void)viewDidLoad
{
    NSLog(@"TOUCHPAD LOADING");
    self->_waitingForScreensLabel = "Waiting for screens ...";
    
    [super viewDidLoad];
    
    AppDelegate* app = [[UIApplication sharedApplication] delegate];
    self->_synergy = app._synergy;
    self->_screenCount = 0;
    self->_screenNames.clear();
    self->_screenNames.push_back(self->_waitingForScreensLabel);
    
    self.picker.delegate = self;
    self.picker.dataSource = self;
    
    [self updateAvailableScreens];
    
    if(!app._synergy) {
        NSLog(@"Synergy object NOT INITIALIZED!!!");
    }
    if(!self->_synergy) {
        NSLog(@"Synergy object NOT INITIALIZED!!!");
    }
    
    [self->_synergy inspect];
    
    [self->_synergy registerListener:self];
    NSLog(@"TOUCHPAD LOADED"); 
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self->_screenNames.size();
}

- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [NSString stringWithFormat:@"%s", self->_screenNames[row].c_str()];
}

- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component
{
    [self->_synergy activate:self->_screenNames[row].c_str()];
}

- (void)addScreen:(const char*)name
{
    NSLog(@"WILL ADD SCREEN: %s", name);
    if(self->_screenCount == 0) {
        self->_screenNames[0] = std::string(name);
    } else {
        self->_screenNames.push_back(std::string(name));
    }

    [self updateAvailableScreens];
    
    self->_screenCount++;
}

- (void)removeScreen:(const char *)name
{
    NSLog(@"Looking for screen");
    CFXScreenNames::const_iterator i = std::find(self->_screenNames.begin(), self->_screenNames.end(), name);
    
    NSLog(@"Searching for %s", name);

    if(i != self->_screenNames.end()) {
        NSLog(@"Will remove %s", name);
        self->_screenNames.erase(i);
        self->_screenCount--;
        if(self->_screenCount == 0) {
            self->_screenNames.push_back(self->_waitingForScreensLabel);
        }
        NSLog(@"Done removing");
    }
    
    [self updateAvailableScreens];
}

- (void)touchesBegan:(NSSet *)touches
           withEvent:(UIEvent *)event
{

    NSLog(@"TBEGAN");
    UITouch *touched = [[event allTouches] anyObject];
    CGPoint location = [touched locationInView:touched.view];
    CFXPoint* p = [[CFXPoint alloc] initWith:location.x andWith:location.y];
    
    [self->_synergy beginMouseMove: p];
}

- (void)touchesMoved:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    NSLog(@"TMOVED");
    UITouch *touched = [[event allTouches] anyObject];
    CGPoint location = [touched locationInView:touched.view];
    CFXPoint* p = [[CFXPoint alloc] initWith:location.x andWith:location.y];
    
    [self->_synergy mouseMove: p];
}

- (void)touchesEnded:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    NSLog(@"TENDED");
    for (UITouch *aTouch in touches) {
        if (aTouch.tapCount >= 2) {
            [self->_synergy doubleClick: kCFXRight];
        } else if(aTouch.tapCount == 1) {
            [self->_synergy click: kCFXRight];
        }
    }
}

- (void)receive:(CFXSynergyEvent)event
           with:(const void *)payload
{
    if(event == kCFXSynergyNewScreen) {
        [self addScreen:(const char*)payload];
    } else if(event == kCFXSynergyScreenLost) {
        [self removeScreen:(const char*)payload];
    }
}

- (void)updateAvailableScreens
{
    NSLog(@"WIll reload components");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.picker reloadAllComponents];
        NSLog(@"Reloaded components");
    });
}

@end
