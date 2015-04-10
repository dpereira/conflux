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

@interface KeyboardViewController ()

@end

@implementation KeyboardViewController

- (void)viewDidLoad
{
    // FIXME: there must be a less
    // hackish way to accomplish this.
    UITextView *textArea = self.view.subviews[0];
    textArea.delegate = self;
    [textArea becomeFirstResponder];
}

- (void)textViewDidChange:(UITextView *)textView
{
    UITextView *textArea = self.view.subviews[0];
    UInt16 c = [textArea.text characterAtIndex:textArea.text.length - 1];
    AppDelegate* app = [[UIApplication sharedApplication] delegate];
    [app._synergy keyStroke: c];
}

@end
