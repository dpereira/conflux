//
//  synergy.h
//  Conflux for iOS
//
//  Created by Diego Pereira on 2/1/15.
//  Copyright (c) 2015 Conflux. All rights reserved.
//

#ifndef Conflux_for_iOS_synergy_h
#define Conflux_for_iOS_synergy_h

#import <CoreFoundation/CoreFoundation.h>
#import "Point.h"
#import "Mouse.h"

@interface CFXSynergy: NSObject

- (void) load:(CFXPoint*)sourceResolution;

- (void) unload;

- (void) beginMouseMove:(CFXPoint*)coordinates;

- (void) mouseMove:(CFXPoint*)coordinates;

- (void) doubleClick:(CFXMouseButton)whichButton;

- (void) click:(CFXMouseButton)whichButton;

- (void) changeOrientation;

@end

#endif
