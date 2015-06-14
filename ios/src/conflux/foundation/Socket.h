// Defines a protocol for sockets.
// The primary motivation is injecting
// mock socket objects and remove
// coupling from CF* code.

#ifndef conflux_socket_h
#define conflux_socket_h

#import <CoreFoundation/CoreFoundation.h>

typedef enum {
    kCFXSocketConnected,
    kCFXSocketReceivedData
} CFXSocketEvent;

@protocol CFXSocket;

@protocol CFXSocketListener <NSObject>
- (void)receive:(CFXSocketEvent)event
     fromSender:(id<CFXSocket>)socket
    withPayload:(void*)data;
@end

@protocol CFXSocket <NSObject>

- (void)listen:(UInt16)port;

- (void)open;

- (size_t)recv:(UInt8*)buffer
         bytes:(size_t)howMany;

- (size_t)send:(const UInt8*)buffer
         bytes:(size_t)howMany;

- (void)registerListener:(id<CFXSocketListener>)listener;

- (void)disconnect;

- (void)setSocket:(int)socket;

@end

@interface CFXFoundationSocket : NSObject <CFXSocket>

- (id)init;

@end

#endif
