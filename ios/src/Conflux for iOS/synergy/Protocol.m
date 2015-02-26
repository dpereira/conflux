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
#import <Foundation/Foundation.h>
#import <sys/socket.h>


@implementation CFXProtocol {
    CFWriteStreamRef _writeStream;
    CFReadStreamRef _readStream;
}


-(id)initWithSocket:(CFSocketNativeHandle*)socket {
    if(self = [super init]) {
        CFStreamCreatePairWithSocket(kCFAllocatorDefault, *socket, &self->_readStream, &self->_writeStream);
        
        if(!CFReadStreamOpen(self->_readStream)) {
            NSLog(@"Failed to open read stream");
            return nil;
        }
        
        if(!CFWriteStreamOpen(self->_writeStream)) {
            NSLog(@"Failed to open write stream");
            return nil;
        }
        
        return self;
    } else {
        return nil;
    }
}

-(void)hail {
    UInt8 hail[] = {0x53, 0x79, 0x6e, 0x65, 0x72, 0x67, 0x79, 0x00, 0x01, 0x00, 0x05};
    [self _writeRaw:hail bytes:sizeof(hail)];
}

-(void)qinf {
    [self _writeSimple:"QINF"];
}

-(void)ciak {
    [self _writeSimple:"CIAK"];
}

-(void)crop {
    [self _writeSimple:"CROP"];
}

-(void)dsop {
    [self _writeSimple:"DSOP"];
}

-(void)calv {
    [self _writeSimple:"CALV"];
}

-(void)cinn:(const CFXPoint *)coordinates {
    NSLog(@"Entering screen");
    UInt16 x = coordinates.x;
    UInt16 y = coordinates.y;
    const UInt8 cmd[] = {(UInt8)'C', (UInt8)'I', (UInt8)'N', (UInt8)'N', x >> 8, x & 0x00FF, y >> 8, y & 0x00FF };
    [self _writeRaw:cmd bytes:sizeof(cmd)];
    
}

-(void)dmov:(const CFXPoint *)coordinates {
    NSLog(@"Moving mouse");
    UInt16 x = coordinates.x;
    UInt16 y = coordinates.y;
    const UInt8 cmd[] = {'D','M','M','V', x >> 8, x & 0x00FF, y >> 8, y & 0x00FF};
    [self _writeRaw:cmd bytes:sizeof(cmd)];
}

-(void)dmdn:(CFXMouseButton)whichButton {
    NSLog(@"Mouse down: %02x", whichButton);
    const UInt8 cmd[] = {'D','M','D','N', whichButton };
    [self _writeRaw:cmd bytes:sizeof(cmd)];
}

-(void)dmup:(CFXMouseButton)whichButton {
    NSLog(@"Mouse up: %02x", whichButton);    
    const UInt8 cmd[] = {'D','M','U','P', whichButton };
    [self _writeRaw:cmd bytes:sizeof(cmd)];
}

-(void)_writeRaw:(const UInt8 *)bytes bytes:(int)howMany {
    UInt8 header[] = {0x00, 0x00, 0x00, howMany };
    UInt8 *buffer = malloc(sizeof(header) + howMany);
    memcpy(buffer, header, sizeof(header));
    memcpy(buffer + sizeof(header), bytes, howMany);
    CFWriteStreamWrite(self->_writeStream, buffer, sizeof(header) + howMany);
    free(buffer);
}

-(void)_writeSimple:(const char *)payload {
    NSLog(@"-> %s", payload);
    [self _writeRaw:(const UInt8 *)payload bytes:(int)strlen(payload)];
}

- (UInt8) peek {
    UInt8 headerBuffer[4];
    memset(headerBuffer, 0, sizeof(headerBuffer));
    CFReadStreamRead(self->_readStream, headerBuffer, sizeof(headerBuffer));
    
    return headerBuffer[3];
}

-(CFXCommand)waitCommand:(UInt8*)buffer
                   bytes:(size_t)toRead {
    memset(buffer, 0, toRead);
    CFReadStreamRead(self->_readStream, buffer, toRead);    
    return [self _classify:buffer];
}

- (CFXCommand)_classify:(UInt8*) cmd {
    // Always make this match the CFXCommand
    // enum or this method will stop working properly.
    const char* commandIds[] = {
        "NONE",
        "HAIL",
        "QINF",
        "DINF",
        "CALV",
        "CIAK",
        "DSOP",
        "CROP",
        "CINN",
        "DMOV",
        "DMDN",
        "DMUP"
    };
    
    char identifier[5]; identifier[4] = 0;
    strncpy(identifier, (const char*)cmd, 4);
    
    for(int i = 0; i < sizeof(commandIds) / sizeof(char*); i++) {
        if(strcmp(identifier, commandIds[i]) == 0) {
            NSLog(@"<- %s", identifier);
            return (CFXCommand)i;
        } else if(strcmp(identifier, "Syne"/*rgy*/) == 0) { // cheating
            return HAIL;
        }
    }
    
    NSLog(@"!! unable to classify: %s", identifier);
    
    return NONE;
}



@end