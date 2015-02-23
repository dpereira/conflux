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

@implementation CFXProtocol

-(id)initWithSocket:(CFSocketRef)socket {
    if(self = [super init]) {
        return self;
    } else {
        return nil;
    }
}

-(void)writeRaw:(const UInt8 *)bytes bytes:(int)howMany toStream:(CFWriteStreamRef)writeStream {
}

-(void)writeSimple:(const char *)payload toStream:(CFWriteStreamRef)writeStream {
}

-(void)handshake {
}

-(void)calv {
}

-(void)cinn:(const CFXPoint *)coordinates toStream:(CFWriteStreamRef)writeStream {
}

-(void)dmov:(const CFXPoint *)coordinates toStream:(CFWriteStreamRef)writeStream {
}

-(void)dmdn:(const int)whichButton toStream:(CFWriteStreamRef)writeStream {
}

-(void)dmup:(const int)whichButton toStream:(CFWriteStreamRef)writeStream {
}


@end