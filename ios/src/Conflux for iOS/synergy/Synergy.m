//
//  synergy.m
//  Conflux for iOS
//
//  Created by Diego Pereira on 2/1/15.
//  Copyright (c) 2015 Conflux. All rights reserved.
//


#import <sys/socket.h>
#import <netinet/in.h>
#import "Foundation/Foundation.h"
#import "Synergy.h"
#import "Protocol.h"
#import "Mouse.h"

@interface Synergy()

@property CFXProtocol* _protocol;

@property CFSocketRef _socket;

@property int _state;

-(id)init;

-(void)_addClient:(CFSocketNativeHandle*)clientSocket;

@end

/*
static void handleReadStream(CFReadStreamRef readStream, CFStreamEventType type, void *info)
{
    UInt8 buffer[8];
    memset(buffer, 0, sizeof(buffer));
    
    if(kCFStreamEventHasBytesAvailable == type) {
        CFIndex howMany = CFReadStreamRead(readStream, buffer, sizeof(buffer));
        NSLog(@"Read %d bytes", (int)howMany);
    } else if(kCFStreamEventErrorOccurred) {
        NSLog(@"Error reading stream");
    }
    
    NSLog(@"OK");
}
*/

static void handleConnect(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void* data, void* info)
{
    if(kCFSocketAcceptCallBack == type) {
        Synergy* synergy = (__bridge Synergy*)info;
        [synergy _addClient:(CFSocketNativeHandle*)data];
    }
}

@implementation Synergy {
    double _sourceX, _sourceY, _targetX, _targetY;
    double _xProjection;
    double _yProjection;
}

-(void)_updateProjection {
    self->_xProjection = self->_targetX / self->_sourceX;
    self->_yProjection = self->_targetY / self->_sourceY;
}

-(id)init {
    if(self = [super init]) {
        self->_sourceX = 320.;
        self->_sourceY = 480.;
        self->_targetX = 1280.;
        self->_targetY = 800.;
        [self _updateProjection];
        
        self._socket = [self _initSocket];
        return self;
    } else {
        return nil;
    }
}

-(void) changeOrientation {
    NSLog(@"Orientation changed: %f, %f", self->_xProjection, self->_yProjection);
    double tmp = self->_sourceX;
    self->_sourceX = self->_sourceY;
    self->_sourceY = tmp;
    [self _updateProjection];
}

-(void) click:(CFXMouseButton) whichButton {
    [self._protocol dmdn: whichButton];
    [self._protocol dmup: whichButton];
}

- (void) doubleClick:(CFXMouseButton) whichButton {
    [self click: whichButton];
    [self click: whichButton];
}

- (void) mouseMove:(CFXPoint*)coordinates {
    CFXPoint* projected = [CFXPoint new];
    projected.x = coordinates.x * self->_xProjection;
    projected.y = coordinates.y * self->_yProjection;
    [self._protocol dmov: projected];
}
-(void)_addClient:(CFSocketNativeHandle*)clientSocket {
    self._state = 0;
    
    self._protocol = [[CFXProtocol alloc] initWithSocket: clientSocket];
    
    [self._protocol hail];
    
    [self _processPacket:nil bytes:0];
    
    while([self._protocol waitCommand]) {
        [self _processPacket:nil bytes:0];
        
        if(self._state == 3) {
            break;
        }
    }
    
    [self._protocol cinn: [[CFXPoint alloc] initWith:0 and:0]];
}

-(void) _processPacket:(UInt8*) buffer
                 bytes:(int)numBytes {
    switch(self._state) {
        case 0: self._state = 1; break;
        case 1: [self._protocol qinf]; self._state = 2; break;
        case 2:
            [self._protocol ciak];
            [self._protocol crop];
            [self._protocol dsop];
            self._state = 3;
            [NSTimer scheduledTimerWithTimeInterval:2.0f
                                             target:self
                                           selector:@selector(_keepAlive:)
                                           userInfo:nil repeats:YES
             ];
            
            break;
        default: break;
    }
}

- (CFSocketRef) _initSocket {
    CFSocketContext ctx = {0, (__bridge void*)self, NULL, NULL, NULL};
    CFSocketRef myipv4cfsock = CFSocketCreate(kCFAllocatorDefault,
                                              PF_INET,
                                              SOCK_STREAM,
                                              IPPROTO_TCP,
                                              kCFSocketAcceptCallBack, handleConnect, &ctx);
    struct sockaddr_in sin;
    
    memset(&sin, 0, sizeof(sin));
    sin.sin_len = sizeof(sin);
    sin.sin_family = AF_INET;
    sin.sin_port = htons(24800);
    sin.sin_addr.s_addr= INADDR_ANY;
    
    CFDataRef sincfd = CFDataCreate(kCFAllocatorDefault,
                                    (UInt8 *)&sin,
                                    sizeof(sin));
    
    CFSocketSetAddress(myipv4cfsock, sincfd);
    CFRelease(sincfd);
    
    CFRunLoopSourceRef socketsource = CFSocketCreateRunLoopSource(kCFAllocatorDefault,
                                                                  myipv4cfsock,
                                                                  0);
    
    CFRunLoopAddSource(CFRunLoopGetCurrent(),
                       socketsource,
                       kCFRunLoopDefaultMode);
    
    return myipv4cfsock;
}

-(void)_keepAlive:(NSTimer*)timer {
    [self._protocol calv];
}

@end
