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
#import <sys/select.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <pthread.h>
#import <errno.h>
#import <string.h>

@interface CFXFoundationSocket()

-(id)initWith:(int)handle;

-(void)_handleConnect:(int)clientSocket;

-(void)_handleReadStream;

@end

typedef struct {
    uint16_t port;
    void* confluxSocket;
} CFXConnectionParameters;

typedef struct {
    int socket;
    void* confluxSocket;
} CFXReadParameters;

static void* _posixHandleConnect(void *args) {
    CFXConnectionParameters *params = (CFXConnectionParameters*)args;

    struct sockaddr_in sin;
    memset(&sin, 0, sizeof(sin));
    sin.sin_len = sizeof(sin);
    sin.sin_family = AF_INET;
    sin.sin_port = htons(params->port);
    sin.sin_addr.s_addr= INADDR_ANY;
    
    int s = socket(AF_INET, SOCK_STREAM, 0);
    int yes = 1;
    
    if(setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(int)) < 0) {
        NSLog(@"FAILED TO SET SOCKET OPTIONS -> ERROR WAS %s", strerror(errno));
    }
    
    [(__bridge CFXFoundationSocket*)params->confluxSocket setSocket:s];
    
    if(s <= 0) {
        NSLog(@"FAILED TO CREATE SOCKET -> ERROR WAS: %s", strerror(errno));
        return NULL;
    }
    
    if(bind(s, (struct sockaddr*)&sin, sizeof(sin)) < 0) {
        NSLog(@"FAILED TO BIND SOCKET -> ERROR WAS: %s", strerror(errno));
        return NULL;
    }
    
    if(listen(s, 10) < 0) {
        NSLog(@"FAILED TO LISTEN -> ERROR WAS: %s", strerror(errno));
        return NULL;
    }
    
    sockaddr_in clientAddress;
    socklen_t addressLength = sizeof(clientAddress);
    int clientSocket;
    while((clientSocket = accept(s, (sockaddr*)&clientAddress, &addressLength)) > 0) {
        [(__bridge CFXFoundationSocket*)params->confluxSocket _handleConnect:clientSocket];
    }
    NSLog(@"THREAD HAS BEEN EXITED: %d", clientSocket);
    NSLog(@"ERROR WAS: %s", strerror(errno));
    return NULL;
}

static void* _posixHandleReadStream(void* args) {
    CFXReadParameters *params = (CFXReadParameters*)args;
    int socket = params->socket;
    
    fd_set nothing, socketSet, errorSet;
    FD_ZERO(&nothing);
    FD_SET(socket, &socketSet);
    FD_SET(socket, &errorSet);
    
    int result = 0;
    
    while((result = select(socket + 1, &socketSet, &nothing, &errorSet, NULL)) > 0) {
        [(__bridge CFXFoundationSocket*)params->confluxSocket _handleReadStream];
    }
    
    NSLog(@"READ LOOP COMPROMISED: exiting with %d", result);
    
    return NULL;
}

@implementation CFXFoundationSocket {

bool _disconnecting;
int _serverSocket;
int _clientSocket;
id<CFXSocketListener> _listener;
    
}

- (id)initWith:(int)handle
{
    if(self = [super init]) {
        self->_clientSocket = handle;
        self->_serverSocket = 0;
        self->_disconnecting = NO;
        return self;
    } else {
        return nil;
    }
}

- (id)init
{
    if(self = [super init]) {
        self->_clientSocket = 0;
        self->_serverSocket = 0;
        self->_disconnecting = NO;
        return self;
    } else {
        return nil;
    }
}
- (void)setSocket:(int) socket
{
    self->_serverSocket = socket;
}

- (void)registerListener:(id<CFXSocketListener>)listener
{
    self->_listener = listener;
}

- (void)open
{
    CFXReadParameters *params = (CFXReadParameters*)malloc(sizeof(CFXReadParameters));
    params->socket = self->_clientSocket;
    params->confluxSocket = (__bridge void*)self;
    pthread_t thread;
    pthread_attr_t attributes;
    
    if(pthread_attr_init(&attributes) != 0) {
        NSLog(@"Failed to initalize thread attributes");
    }
    
    pthread_create(&thread, &attributes, &_posixHandleReadStream, params);
}

- (void)listen:(uint16_t)port
{
    CFXConnectionParameters *params = (CFXConnectionParameters*)malloc(sizeof(CFXConnectionParameters));
    params->port = port;
    params->confluxSocket = (__bridge void*)self;
    pthread_t thread;
    pthread_attr_t attributes;
    
    if(pthread_attr_init(&attributes) != 0) {
        NSLog(@"Failed to initalize thread attributes");
    }
    
    pthread_create(&thread, &attributes, &_posixHandleConnect, params);
}

- (size_t)send:(const UInt8 *)buffer bytes:(size_t)howMany
{
    //NSLog(@"X DD: socket %d getting %lu bytes sent to", self->_clientSocket, howMany);
    return send(self->_clientSocket, buffer, howMany, 0);
}

-(size_t)recv:(UInt8 *)buffer bytes:(size_t)howMany
{
    //NSLog(@"X DD: socket %d getting %lu bytes received from", self->_clientSocket, howMany);
    return recv(self->_clientSocket, buffer, howMany, 0);
}

- (void)disconnect
{
    self->_disconnecting = YES;
    
    if(self->_clientSocket) {
        close(self->_clientSocket);
        self->_clientSocket = 0;
        NSLog(@"Client socket disconnected");
    }
    
    if(self->_serverSocket) {
        close(self->_serverSocket);
        self->_serverSocket = 0;
        NSLog(@"Server socket disconnected");
    }
}

- (void)_handleConnect:(int)clientSocket
{
    if(self->_disconnecting) {
        return;
    }
    
    id<CFXSocket> socket = [[CFXFoundationSocket alloc] initWith:clientSocket];
    
    [self->_listener receive:kCFXSocketConnected
                  fromSender:self
                 withPayload:(__bridge void*)socket];
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

