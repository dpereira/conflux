//
//  Socket.m
//  conflux
//
//  Created by Diego Pereira on 3/4/15.
//  Copyright (c) 2015 Conflux. All rights reserved.
//

#import "Socket.h"
#import <Foundation/Foundation.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <pthread.h>
#import <errno.h>
#import <string.h>

@interface CFXFoundationSocket()

-(id)initWith:(CFSocketNativeHandle*)handle;

-(void)_handleConnect:(CFSocketNativeHandle*)clientSocket;

-(void)_handleReadStream;

@end

typedef struct {
    char* canary;
    CFSocketRef socket;
    CFXFoundationSocket* confluxSocket;
} CFXConnectionParameters;

static void* _posixHandleConnect(void *args) {
    CFXConnectionParameters *params = (CFXConnectionParameters*)args;
    CFSocketNativeHandle handle = CFSocketGetNative((CFSocketRef)params->socket);
    
    
    if(listen(handle, 10) < 0) {
        NSLog(@"FAILED TO LISTEN -> ERROR WAS: %s", strerror(errno));
        return NULL;
    }
    
    sockaddr_in clientAddress;
    socklen_t addressLength = sizeof(clientAddress);
    CFSocketNativeHandle clientSocket;
    while((clientSocket = (CFSocketNativeHandle)accept(handle, (sockaddr*)&clientAddress, &addressLength)) > 0) {
        int* s = (int*)malloc(sizeof(int));
        NSLog(@"CONNECTION RECEIVED");
        *s = clientSocket;
        [params->confluxSocket _handleConnect:s];
    }
    NSLog(@"THREAD HAS BEEN EXITED: %d", clientSocket);
    NSLog(@"ERROR WAS: %s", strerror(errno));
    return NULL;
}

static void _handleConnect(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void* data, void* info)
{
    if(kCFSocketAcceptCallBack == type) {
        CFXFoundationSocket* socket = (__bridge CFXFoundationSocket*)info;
        [socket _handleConnect:(CFSocketNativeHandle*)data];
    }
}

static void _handleReadStream(CFReadStreamRef readStream, CFStreamEventType eventType, void *ctx)
{
    CFXFoundationSocket* socket = (__bridge CFXFoundationSocket*)ctx;
    [socket _handleReadStream];
}


@implementation CFXFoundationSocket {

bool _disconnecting;
CFRunLoopSourceRef _source;
CFSocketRef _serverSocket;
CFSocketNativeHandle* _clientSocket;
CFReadStreamRef _readStream;
CFWriteStreamRef _writeStream;
id<CFXSocketListener> _listener;
    
}

- (id)initWith:(CFSocketNativeHandle*)handle
{
    if(self = [super init]) {
        self->_clientSocket = handle;
        self->_serverSocket = nil;
        self->_disconnecting = NO;
        return self;
    } else {
        return nil;
    }
}

- (id)init
{
    if(self = [super init]) {
        self->_clientSocket = nil;
        self->_serverSocket = nil;
        self->_disconnecting = NO;
        return self;
    } else {
        return nil;
    }
}

- (void)registerListener:(id<CFXSocketListener>)listener
{
    self->_listener = listener;
}

- (void)open
{
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocket(kCFAllocatorDefault,
                                 *self->_clientSocket,
                                 &readStream,
                                 &writeStream);
    
    self->_readStream = readStream;
    self->_writeStream = writeStream;
    
    CFReadStreamSetProperty(self->_readStream,
                            kCFStreamPropertyShouldCloseNativeSocket,
                            kCFBooleanTrue);
    
    CFWriteStreamSetProperty(self->_writeStream,
                             kCFStreamPropertyShouldCloseNativeSocket,
                             kCFBooleanTrue);

    if(!CFReadStreamOpen(self->_readStream)) {
        NSLog(@"Failed to open read stream");
    }
    
    [self _scheduleReadStreamRead:self->_readStream];
    
    if(!CFWriteStreamOpen(self->_writeStream)) {
        NSLog(@"Failed to open write stream");
    }
    
}

- (void)listenPosix:(CFSocketRef)serverSocket
{
    CFXConnectionParameters *params = (CFXConnectionParameters*)malloc(sizeof(CFXConnectionParameters));
    params->socket = serverSocket;
    params->confluxSocket = self;
    pthread_t thread;
    pthread_attr_t attributes;
    
    if(pthread_attr_init(&attributes) != 0) {
        NSLog(@"Failed to initalize thread attributes");
    }
    
    pthread_create(&thread, &attributes, &_posixHandleConnect, params);
}

- (void)listen:(UInt16)port
{
    CFSocketContext ctx = {0, (__bridge void*)self, NULL, NULL, NULL};
    self->_serverSocket = CFSocketCreate(kCFAllocatorDefault,
                                   PF_INET,
                                   SOCK_STREAM,
                                   IPPROTO_TCP,
                                   kCFSocketAcceptCallBack, _handleConnect, &ctx);
    
    NSLog(@"Socket created %u", self->_serverSocket != NULL);
    
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
    
    [self listenPosix:self->_serverSocket];
    /*
    self->_source = CFSocketCreateRunLoopSource(kCFAllocatorDefault,
                                                self->_serverSocket,
                                                0);
    
    NSLog(@"Created source %u", self->_source != NULL);
    
    CFRunLoopAddSource(CFRunLoopGetCurrent(),
                       self->_source,
                       kCFRunLoopDefaultMode);
    
    NSLog(@"Registered into run loop");
     */
}

- (size_t)send:(const UInt8 *)buffer bytes:(size_t)howMany
{
    return CFWriteStreamWrite(self->_writeStream, buffer, howMany);
}

-(size_t)recv:(UInt8 *)buffer bytes:(size_t)howMany
{
    return CFReadStreamRead(self->_readStream, buffer, howMany);
}

- (void)disconnect
{
    self->_disconnecting = YES;
    
    if(self->_clientSocket) {
        NSLog(@"Disconnecting client socket");
        if(self->_readStream) {
            CFReadStreamUnscheduleFromRunLoop(self->_readStream,
                                              CFRunLoopGetCurrent(),
                                              kCFRunLoopCommonModes);
            CFReadStreamClose(self->_readStream);
            CFRelease(self->_readStream);
            self->_readStream = nil;
            NSLog(@"Read stream released");
        }
        if(self->_writeStream) {
            CFWriteStreamClose(self->_writeStream);
            CFRelease(self->_writeStream);            
            self->_writeStream = nil;
            NSLog(@"Write stream released");            
        }
        
        close(*self->_clientSocket);
        self->_clientSocket = NULL;

        NSLog(@"Client socket disconnected");
    }
    
    if(self->_serverSocket) {
        NSLog(@"Disconnecting server socket");
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), self->_source, kCFRunLoopDefaultMode);
        CFRunLoopSourceInvalidate(self->_source);
        CFRelease(self->_source);
        self->_source = nil;
        CFSocketInvalidate(self->_serverSocket);
        CFRelease(self->_serverSocket);
        self->_serverSocket = nil;
        NSLog(@"Server socket disconnected");
    }
}

- (void)_scheduleReadStreamRead:(CFReadStreamRef)readStream
{
    CFStreamClientContext ctx = {0, (__bridge void*)self, NULL, NULL, NULL};
    CFReadStreamSetClient(readStream, kCFStreamEventHasBytesAvailable, _handleReadStream, &ctx);
    CFReadStreamScheduleWithRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
}


- (void)_handleConnect:(CFSocketNativeHandle *)clientSocket
{
    NSLog(@"HANDLING CONNECT");
    if(self->_disconnecting) {
        return;
    }
    
    id<CFXSocket> socket = [[CFXFoundationSocket alloc] initWith:clientSocket];
    
    [self->_listener receive:kCFXSocketConnected
                  fromSender:self
                 withPayload:(__bridge void*)socket];
    NSLog(@"DONE HANDLING");
}

- (void)_handleReadStream
{
    if(!self->_disconnecting) {
        [self->_listener receive:kCFXSocketReceivedData
                      fromSender:self
                     withPayload:NULL];
    }
}

@end

