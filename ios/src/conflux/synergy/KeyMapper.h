//
//  KeyMapper.h
//  conflux
//
//  Created by Diego Pereira on 5/3/15.
//  Copyright (c) 2015 Conflux. All rights reserved.
//

#ifndef conflux_KeyMapper_h
#define conflux_KeyMapper_h

#import "synergy/key_types.h"

@interface KeyMapper : NSObject

- (UInt16) translate:(UInt16)asciiCodepoint;

- (KeyModifierMask)getKeyModifier:(UInt16)key;

@end

#endif
