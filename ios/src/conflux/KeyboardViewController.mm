#import <Foundation/Foundation.h>
#import "KeyboardViewController.h"
#import "AppDelegate.h"
#import "synergy/Synergy.h"

@interface KeyboardViewController ()

@property NSString *_placeholder;

@end

@implementation KeyboardViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self._placeholder = @" > ";
    
    UITextView *textArea = [self _textArea];
    textArea.delegate = self;
    [textArea becomeFirstResponder];
    textArea.text = self._placeholder;
}

- (void)textViewDidChange:(UITextView *)textView
{
    UITextView *textArea = [self _textArea];
    NSString *text = textArea.text;
    NSUInteger len = text.length;
    textArea.text = self._placeholder;

    AppDelegate* app = [[UIApplication sharedApplication] delegate];
    [app._synergy keyStroke: len > self._placeholder.length ? [text characterAtIndex:len - 1] : '\b'];
}

- (UITextView*)_textArea
{
    // FIXME: there must be a less
    // hackish way to accomplish this.
    return self.view.subviews[0];
}

@end
