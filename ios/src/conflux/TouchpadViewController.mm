#import "TouchpadViewController.h"
#import "AppDelegate.h"
#import <vector>
#import <string>
#import <algorithm>

@interface TouchpadViewController ()

@end

typedef std::vector<std::string> CFXScreenNames;

typedef enum {
    kCFXDefault,
    kCFXDoubleTap
} CFXTouchpadState;

@implementation TouchpadViewController {
    CFXScreenNames _screenNames;
    CFXSynergy* _synergy;
    int _screenCount;
    CFXTouchpadState _state;
    std::string _waitingForScreensLabel;
}

- (void)viewDidLoad
{
    self->_waitingForScreensLabel = "Ready...";
    
    [super viewDidLoad];
    
    [self setupRecognizers];
    
    AppDelegate* app = [[UIApplication sharedApplication] delegate];
    self->_synergy = app._synergy;
    
    self.picker.delegate = self;
    self.picker.dataSource = self;
    
    [self resetScreens];
    
    [self->_synergy registerListener:self];
}

- (void)setupRecognizers
{
    UIPanGestureRecognizer* panRecognizer = [[UIPanGestureRecognizer alloc]
                                                       initWithTarget:self action:@selector(panning:)
                                                       ];
    panRecognizer.minimumNumberOfTouches = 1;
    panRecognizer.maximumNumberOfTouches = 1;
    [self.view addGestureRecognizer:panRecognizer];
    
    UIPanGestureRecognizer* twoFingersPanRecognizer = [[UIPanGestureRecognizer alloc]
                                             initWithTarget:self action:@selector(twoFingersPanning:)
                                            ];
    twoFingersPanRecognizer.minimumNumberOfTouches = 2;
    [self.view addGestureRecognizer:twoFingersPanRecognizer];
    
    UITapGestureRecognizer* tapRecognizer = [[UITapGestureRecognizer alloc]
                                                   initWithTarget:self action:@selector(tapping:)
                                                   ];
    tapRecognizer.numberOfTouchesRequired = 1;
    tapRecognizer.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tapRecognizer];
    
    UITapGestureRecognizer* doubleTapRecognizer = [[UITapGestureRecognizer alloc]
                                             initWithTarget:self action:@selector(doubleTapping:)
                                             ];
    doubleTapRecognizer.numberOfTouchesRequired = 1;
    doubleTapRecognizer.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleTapRecognizer];
    
    UITapGestureRecognizer* twoFingersTapRecognizer = [[UITapGestureRecognizer alloc]
                                                   initWithTarget:self action:@selector(twoFingersTapping:)
                                                   ];
    twoFingersTapRecognizer.numberOfTouchesRequired = 2;
    twoFingersTapRecognizer.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:twoFingersTapRecognizer];
}

- (IBAction)tapping:(UIPanGestureRecognizer*)tapRecognizer
{
    if(tapRecognizer.state == UIGestureRecognizerStateEnded) {
        [self->_synergy click:kCFXRight];
    }
}

- (IBAction)doubleTapping:(UIPanGestureRecognizer*)tapRecognizer
{
    if(tapRecognizer.state == UIGestureRecognizerStateEnded) {
        [self->_synergy doubleClick:kCFXRight];
    }
}

- (IBAction)twoFingersTapping:(UIPanGestureRecognizer*)tapRecognizer
{
    if(tapRecognizer.state == UIGestureRecognizerStateEnded) {
        [self->_synergy click:kCFXLeft];
    }
}

- (IBAction)panning:(UIPanGestureRecognizer*)panRecognizer
{
    if(panRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint p = [panRecognizer locationInView:panRecognizer.view];
        CFXPoint *coordinate = [[CFXPoint alloc] initWith:p.x andWith:p.y];
        [self->_synergy beginMouseMove:coordinate];
    } else if(panRecognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint p = [panRecognizer locationInView:panRecognizer.view];
        CFXPoint *coordinate = [[CFXPoint alloc] initWith:p.x andWith:p.y];
        [self->_synergy mouseMove:coordinate];
    } else if(panRecognizer.state == UIGestureRecognizerStateEnded) {
    }
}

- (IBAction)twoFingersPanning:(UIPanGestureRecognizer*)panRecognizer
{
    if(panRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint p = [panRecognizer locationInView:panRecognizer.view];
        CFXPoint *coordinate = [[CFXPoint alloc] initWith:p.x andWith:p.y];
        [self->_synergy beginMouseScroll:coordinate];
    } else if(panRecognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint p = [panRecognizer locationInView:panRecognizer.view];
        CFXPoint *coordinate = [[CFXPoint alloc] initWith:p.x andWith:p.y];
        [self->_synergy mouseScroll:coordinate];
    } else if(panRecognizer.state == UIGestureRecognizerStateEnded) {
    }
}

- (void)resetScreens
{
    self->_screenCount = 0;
    self->_screenNames.clear();
    self->_screenNames.push_back(self->_waitingForScreensLabel);
    [self updateAvailableScreens];
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
    CFXScreenNames::const_iterator i = std::find(self->_screenNames.begin(), self->_screenNames.end(), name);
    
    if(i != self->_screenNames.end()) {
        self->_screenNames.erase(i);
        self->_screenCount--;
        if(self->_screenCount == 0) {
            [self resetScreens];
        }
    }
    
    [self updateAvailableScreens];
}

/*
- (void)touchesBegan:(NSSet *)touches
           withEvent:(UIEvent *)event
{

    UITouch *touched = [[event allTouches] anyObject];
    CGPoint location = [touched locationInView:touched.view];
    CFXPoint* p = [[CFXPoint alloc] initWith:location.x andWith:location.y];
    
    for (UITouch *aTouch in touches) {
        if (aTouch.tapCount >= 2) {
            self->_state = kCFXDoubleTap;
            NSLog(@"Began double-tap");
        }
    }
    
    if(self->_state == kCFXDoubleTap) {
        [self->_synergy beginMouseDrag: p];
        NSLog(@"Dragging ...");
    } else {
        NSLog(@"Moving ...");
        [self->_synergy beginMouseMove: p];
    }
}

- (void)touchesMoved:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    UITouch *touched = [[event allTouches] anyObject];
    CGPoint location = [touched locationInView:touched.view];
    CFXPoint* p = [[CFXPoint alloc] initWith:location.x andWith:location.y];
    
    [self->_synergy mouseMove: p];
}

- (void)touchesEnded:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    if(self->_state != kCFXDoubleTap) {
        for (UITouch *aTouch in touches) {
            if (aTouch.tapCount >= 2) {
                NSLog(@"D-Click");
                [self->_synergy doubleClick: kCFXRight];
            } else if(aTouch.tapCount == 1) {
                [self->_synergy click: kCFXRight];
                NSLog(@"S-Click");                
            }
        }
    } else {
        self->_state = kCFXDefault;
        [self->_synergy endMouseDrag:NULL];
        NSLog(@"Dragging ended.");
    }
}
*/
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
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.picker reloadAllComponents];
    });
}

@end
