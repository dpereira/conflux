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

typedef enum {
    NONE,
    HAIL,
    QINF,
    CALV,
    CIAK,
    DSOP,
    CROP,
    CINN,
    DMOV,
    DMDN,
    DMUP
} CFXCommand;

@interface CFXProtocol: NSObject

-(id)initWithSocket:(CFSocketNativeHandle*)socket;

-(void)hail; // not a cmd per se, but a handshake sequence

-(void)calv; // server alive

-(void)qinf; // query screen info

-(void)ciak; // ?

-(void)dsop; // ?

-(void)crop; // ?

-(void)cinn:(const CFXPoint *)coordinates; // enter screen @ coordinates

-(void)dmov:(const CFXPoint *)coordinates; // move pointer to coordinates

-(void)dmdn:(const CFXMouseButton)whichButton; // moves given mouse button down (button pressed down)

-(void)dmup:(const CFXMouseButton)whichButton; // moves given mouse button up (btn release)

-(BOOL)waitCommand; // waits for a command from a client

@end

#endif
