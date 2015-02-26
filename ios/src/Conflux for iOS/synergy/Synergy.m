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

@interface CFXSynergy()

@property CFXProtocol* _protocol;

@property CFSocketRef _socket;

@property int _state;

- (void) _addClient:(CFSocketNativeHandle*)clientSocket;

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
        CFXSynergy* synergy = (__bridge CFXSynergy*)info;
        [synergy _addClient:(CFSocketNativeHandle*)data];
    }
}

@implementation CFXSynergy {
    int _sourceWidth, _sourceHeight;
    int _targetWidth, _targetHeight;
    int _remoteCursorX, _remoteCursorY;
    int _currentCursorX, _currentCursorY;
    double _xProjection, _yProjection;
}

- (id) initWithResolution:(CFXPoint *)sourceResolution {
    if(self = [super init]) {
        self->_sourceWidth = sourceResolution.x;
        self->_sourceHeight = sourceResolution.y;
        self->_targetWidth = 1280;
        self->_targetHeight = 800;
        self->_remoteCursorX = self->_remoteCursorY = 1;
        [self _updateProjection];
        
        self._socket = [self _initSocket];
        
        NSLog(@"Initialized source res with: %f, %f", self->_sourceWidth, self->_sourceHeight);
        return self;
    } else {
        return nil;
    }
}

-(id)init {
    if(self = [super init]) {
        self->_sourceWidth = 320;
        self->_sourceHeight = 480;
        self->_targetWidth = 1280;
        self->_targetHeight = 800;
        self->_remoteCursorX = self->_remoteCursorY = 1;
        [self _updateProjection];
        
        self._socket = [self _initSocket];
        return self;
    } else {
        return nil;
    }
}

-(void) changeOrientation {
    NSLog(@"Orientation changed: %f, %f", self->_xProjection, self->_yProjection);
    double tmp = self->_sourceWidth;
    self->_sourceWidth = self->_sourceHeight;
    self->_sourceHeight = tmp;
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

- (void)beginMouseMove:(CFXPoint *)coordinates
{
    self->_currentCursorX = coordinates.x;
    self->_currentCursorY = coordinates.y;
}

- (void) mouseMove:(CFXPoint*)coordinates {
    double projectedDeltaX = (coordinates.x - self->_currentCursorX) * self->_xProjection;
    double projectedDeltaY = (coordinates.y - self->_currentCursorY) * self->_yProjection;
    double projectedX = self->_remoteCursorX + projectedDeltaX;
    double projectedY =self->_remoteCursorY + projectedDeltaY;
    
    
    CFXPoint* projected = [[CFXPoint alloc] initWith:projectedX > 0 ? projectedX : 0
                                                 and:projectedY > 0 ? projectedY : 0];
    
    NSLog(@"!! pd(%f, %f) rc(%d, %d) pj(%d, %d)", projectedDeltaX, projectedDeltaY,
          self->_remoteCursorX, self->_remoteCursorY, projected.x, projected.y);
    
    [self._protocol dmov: projected];
    
    self->_remoteCursorX = projected.x;
    self->_remoteCursorY = projected.y;
    self->_currentCursorX = coordinates.x;
    self->_currentCursorY = coordinates.y;
}

-(void)_updateProjection {
    self->_xProjection = (double)self->_targetWidth / (double)self->_sourceWidth;
    self->_yProjection = (double)self->_targetHeight / (double)self->_sourceHeight;
}

-(void)_addClient:(CFSocketNativeHandle*)clientSocket {
    self._state = 0;
    
    self._protocol = [[CFXProtocol alloc] initWithSocket: clientSocket];
    
    [self._protocol hail];
    
    [self _processPacket:nil ofType:NONE bytes:0];
    
    UInt8 cmdLen = 0;
    while((cmdLen = [self._protocol peek]) > 0) {
        UInt8 buffer[cmdLen];
        CFXCommand type = [self._protocol waitCommand:buffer bytes:cmdLen];
        [self _processPacket:buffer ofType:type bytes:cmdLen];
        
        if(self._state == 3) {
            break;
        }
    }
    
    [self._protocol cinn: [[CFXPoint alloc] initWith:self->_remoteCursorX
                                                 and:self->_remoteCursorY]];
}

-(void) _processPacket:(UInt8*)buffer
                    ofType:(CFXCommand)type
                 bytes:(int)numBytes {
    // process packet data
    switch(type) {
        case DINF: [self _processDinf: buffer bytes:numBytes]; break;
        default:break;
    }
    
    // reply to client
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

- (void) _processDinf:(UInt8 *)buffer
                bytes:(int)numBytes {
    if(numBytes < 18) {
        NSLog(@"EE DINF response expected at least 18 bytes. Got %d. Skipping packet.", numBytes);
        return;
    }
    
    // client info response
    UInt16 targetWidth = (buffer[8] << 8)+ buffer[9];
    UInt16 targetHeight = (buffer[10] << 8) + buffer[11];
    UInt16 remoteCursorX = (buffer[14] << 8) + buffer[15];
    UInt16 remoteCursorY = (buffer[16] << 8) + buffer[17];
    NSLog(@"!! Info received: tX: %d, tY: %d, cX: %d, cy: %d",
           targetWidth, targetHeight, remoteCursorX, remoteCursorY);
    self->_targetWidth = targetWidth;
    self->_targetHeight = targetHeight;
    self->_remoteCursorX = remoteCursorX;
    self->_remoteCursorY = remoteCursorY;
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
