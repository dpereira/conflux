//
//  KeyboardViewController.m
//  conflux
//
//  Created by Diego Pereira on 4/7/15.
//  Copyright (c) 2015 Conflux. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KeyboardViewController.h"
#import "AppDelegate.h"
#import "synergy/Synergy.h"
@import UIKit;

@interface KeyboardViewController ()

@property NSString *_previousText;

@end

@implementation KeyboardViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self._previousText = @">";
    // FIXME: there must be a less
    // hackish way to accomplish this.
    UITextView *textArea = self.view.subviews[0];
    textArea.delegate = self;
    [textArea becomeFirstResponder];
    textArea.text = self._previousText;
    textArea.frame = [[UIScreen mainScreen] bounds];
}

- (void)textViewDidChange:(UITextView *)textView
{
    UITextView *textArea = self.view.subviews[0];
    UInt16 c = [textArea.text characterAtIndex:textArea.text.length - 1];
    AppDelegate* app = [[UIApplication sharedApplication] delegate];
    [app._synergy keyStroke: c];
}

- (NSString*)_textAreaDelta
{
    UITextView *textArea = self.view.subviews[0];
    NSString *currentText = textArea.text;
    if(currentText.length > 1) {
        return [currentText stringByReplacingOccurrencesOfString:self._previousText withString:@""];
    } else {
        return NULL;
    }
}

@end
