//
//  Protocol.h
//  Conflux for iOS
//
//  Created by Diego Pereira on 2/22/15.
//  Copyright (c) 2015 Conflux. All rights reserved.
//

#ifndef Conflux_for_iOS_Protocol_h
#define Conflux_for_iOS_Protocol_h

#import <Foundation/Foundation.h>
#import "Point.h"
#import "Mouse.h"


@interface CFXProtocol: NSObject

-(id)initWithSocket:(CFSocketRef)socket;

-(void)handshake;

-(void)calv;

-(void)cinn:(const CFXPoint *)coordinates;

-(void)dmov:(const CFXPoint *)coordinates;

-(void)dmdn:(const CFXMouseButton)whichButton;

-(void)dmup:(const CFXMouseButton)whichButton;

@end

#endif
