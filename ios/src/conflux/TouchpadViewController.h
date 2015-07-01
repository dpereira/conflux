#import <UIKit/UIKit.h>
#import "synergy/Synergy.h"

@interface TouchpadViewController : UIViewController<UIPickerViewDataSource, UIPickerViewDelegate, CFXSynergyListener>
@property (weak, nonatomic) IBOutlet UIPickerView *picker;

- (void)resetScreens;

@end

