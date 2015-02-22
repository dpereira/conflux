//
//  synergy.h
//  Conflux for iOS
//
//  Created by Diego Pereira on 2/1/15.
//  Copyright (c) 2015 Conflux. All rights reserved.
//

#ifndef Conflux_for_iOS_synergy_h
#define Conflux_for_iOS_synergy_h

@import Foundation;

@interface Synergy: NSObject
-(void)loop;
-(void)mouseMove: (UInt16) x withY:(UInt16)y;
-(void)doubleClick: (UInt8)whichButton;
@end

#endif
