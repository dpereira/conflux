//
//  Protocol.m
//  Conflux for iOS
//
//  Created by Diego Pereira on 2/22/15.
//  Copyright (c) 2015 Conflux. All rights reserved.
//
//  Holds the implementation of methods directly related
//  with the synergy protocol
//

#import "Protocol.h"

@interface CFXProtocol()

@property CFWriteStreamRef _writeStream;

@property CFReadStreamRef _readStream;

@end

@implementation CFXProtocol

-(id)initWithSocket:(CFSocketRef)socket {
    if(self = [super init]) {
        return self;
    } else {
        return nil;
    }
}

-(void)handshake {
}

-(void)calv {
}

-(void)cinn:(const CFXPoint *)coordinates {
}

-(void)dmov:(const CFXPoint *)coordinates {
}

-(void)dmdn:(CFXMouseButton)whichButton {
}

-(void)dmup:(CFXMouseButton)whichButton {
}

-(void)_writeRaw:(const UInt8 *)bytes bytes:(int)howMany {
}

-(void)_writeSimple:(const char *)payload {
}



@end