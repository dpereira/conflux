//
//  KeyboardViewController.m
//  conflux
//
//  Created by Diego Pereira on 4/7/15.
//  Copyright (c) 2015 Conflux. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KeyboardViewController.h"

@interface KeyboardViewController ()

@end

@implementation KeyboardViewController

- (void)viewDidLoad {
    // FIXME: there must be a less
    // hackish way to accomplish this.
    [self.view.subviews[0] becomeFirstResponder];
}

@end
