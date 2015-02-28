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
    CNOP,    
    QINF,
    DINF,
    CALV,
    CIAK,
    DSOP,
    CROP,
    CINN,
    DMOV,
    DMDN,
    DMUP
} CFXCommand;

@protocol CFXProtocolListener <NSObject>

- (void)receive:(UInt8*)cmd
         ofType:(CFXCommand)type
     withLength:(size_t)length;

@end

@interface CFXProtocol: NSObject

- (id)initWithSocket:(CFSocketNativeHandle*)socket
        andListener:(id<CFXProtocolListener>)listener;

- (void)unload;

- (void)hail; // not a cmd per se, but a handshake sequence

- (void)calv; // server alive

- (void)qinf; // query screen info

- (void)ciak; // ?

- (void)dsop; // ?

- (void)crop; // ?

- (void)cinn:(const CFXPoint *)coordinates; // enter screen @ coordinates

- (void)dmov:(const CFXPoint *)coordinates; // move pointer to coordinates

- (void)dmdn:(const CFXMouseButton)whichButton; // moves given mouse button down (button pressed down)

- (void)dmup:(const CFXMouseButton)whichButton; // moves given mouse button up (btn release)

- (UInt8) peek;

- (CFXCommand) waitCommand:(UInt8*)buffer
                     bytes:(size_t)toRead; // waits for a command from a client

- (void)processCmd:(UInt8*)cmd
            ofType:(CFXCommand)type
             bytes:(size_t)toSend;

@end

#endif
