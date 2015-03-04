//
//  Socket.m
//  conflux
//
//  Created by Diego Pereira on 3/4/15.
//  Copyright (c) 2015 Conflux. All rights reserved.
//

#import "Socket.h"
#import <CoreFoundation/CoreFoundation.h>
#import <sys/socket.h>
#import <netinet/in.h>

@interface CFXFoundationSocket()
-(id)initWith:(CFSocketNativeHandle*)handle;
-(void)_handleConnect:(CFSocketNativeHandle*)clientSocket;
@end

static void _handleConnect(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void* data, void* info)
{
    if(kCFSocketAcceptCallBack == type) {
        CFXFoundationSocket* socket = (__bridge CFXFoundationSocket*)info;
        [socket _handleConnect:(CFSocketNativeHandle*)data];
    }
}

@implementation CFXFoundationSocket {
    CFRunLoopSourceRef _source;
    CFSocketRef _serverSocket;
    CFSocketNativeHandle* _clientSocket;
    id<CFXSocketListener> _listener;
}

- (id)initWith:(CFSocketNativeHandle*)handle
{
    if(self = [super init]) {
        self->_clientSocket = handle;
        self->_serverSocket = nil;
        return self;
    } else {
        return nil;
    }
}

- (id)init
{
    if(self = [super init]) {
        self->_clientSocket = nil;
        return self;
    } else {
        return nil;
    }
}

- (void)bindTo:(UInt16)port
{
    CFSocketContext ctx = {0, (__bridge void*)self, NULL, NULL, NULL};
    self->_serverSocket = CFSocketCreate(kCFAllocatorDefault,
                                   PF_INET,
                                   SOCK_STREAM,
                                   IPPROTO_TCP,
                                   kCFSocketAcceptCallBack, _handleConnect, &ctx);
    
    struct sockaddr_in sin;
    memset(&sin, 0, sizeof(sin));
    sin.sin_len = sizeof(sin);
    sin.sin_family = AF_INET;
    sin.sin_port = htons(port);
    sin.sin_addr.s_addr= INADDR_ANY;
    
    CFDataRef sincfd = CFDataCreate(kCFAllocatorDefault,
                                    (UInt8 *)&sin,
                                    sizeof(sin));
    CFSocketSetAddress(self->_serverSocket, sincfd);
    CFRelease(sincfd);
    
    self->_source = CFSocketCreateRunLoopSource(kCFAllocatorDefault,
                                                self->_serverSocket,
                                                0);
    
    CFRunLoopAddSource(CFRunLoopGetCurrent(),
                       self->_source,
                       kCFRunLoopDefaultMode);
}

- (void)registerListener:(id<CFXSocketListener>)listener
{
    self->_listener = listener;
}

- (void)disconnect
{
    if(self->_serverSocket) {
    }
}

- (void)_handleConnect:(CFSocketNativeHandle *)clientSocket
{
    id<CFXSocket> socket = [[CFXFoundationSocket alloc] initWith:clientSocket];
    
    [self->_listener receive:kCFXSocketConnected
                  fromSender:self
                 withPayload:(__bridge void*)socket];
}

@end

