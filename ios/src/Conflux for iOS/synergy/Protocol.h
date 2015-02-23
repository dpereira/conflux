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

-(void)writeRaw:(const UInt8 *)bytes
          bytes:(int)howMany
       toStream:(CFWriteStreamRef)writeStream;

-(void)writeSimple:(const char *)payload
          toStream:(CFWriteStreamRef)writeStream;

-(void)cinn:(const CFXPoint *)coordinates
   toStream:(CFWriteStreamRef)writeStream;

-(void)dmov:(const CFXPoint *)coordinates
   toStream:(CFWriteStreamRef)writeStream;

-(void)dmdn:(const CFXMouseButton)whichButton
   toStream:(CFWriteStreamRef)writeStream;

-(void)dmup:(const CFXMouseButton)whichButton
   toStream:(CFWriteStreamRef)writeStream;

@end

#endif
