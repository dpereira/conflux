// Defines a protocol for sockets.
// The primary motivation is injecting
// mock socket objects.
#ifndef conflux_socket_h
#define conflux_socket_h

#import <CoreFoundation/CoreFoundation.h>

typedef enum {
    kCFXSocketConnected
} CFXSocketEvent;

@protocol CFXSocketListener <NSObject>

- (void)receive:(CFXSocketEvent)event
     fromSender:(CFXSocket)socket;

@end

@protocol CFXSocket <NSObject>

- (void)bindTo:(UInt8[4])address
        atPort:(UInt16)port;

- (void)registerListener:(id<CFXSocketListener>)listener;

@end

#endif
