#ifndef Conflux_for_iOS_Protocol_h
#define Conflux_for_iOS_Protocol_h

#import <Foundation/Foundation.h>
#import "Point.h"
#import "Mouse.h"
#import "Socket.h"

#define SYNERGY_PKTLEN_MAX 4096
#define SYNERGY_HEADER_LEN 4

typedef enum
{
    NONE,
    HAIL,
    CNOP,
    QINF,
    DINF,
    CALV,
    CIAK,
    DSOP,
    CROP,
    CINN,
    DMOV,
    DMDN,
    DMUP,
    TERM
} CFXCommand;

@protocol CFXProtocolListener;

@interface CFXProtocol: NSObject <CFXSocketListener>

- (id)initWithSocket:(id<CFXSocket>)socket
        andListener:(id<CFXProtocolListener>)listener;

- (void)unload;

- (int)idTag;

- (void)runTimer;

- (void)hail; // not a cmd per se, but a handshake sequence

- (void)calv; // server alive

- (void)qinf; // query screen info

- (void)ciak; // ?

- (void)dsop; // ?

- (void)crop; // ?

- (void)cinn:(const CFXPoint *)coordinates; // enter screen @ coordinates

- (void)dmov:(const CFXPoint *)coordinates; // move pointer to coordinates

- (void)dmdn:(const CFXMouseButton)whichButton; // moves given mouse button down (button pressed down)

- (void)dmup:(const CFXMouseButton)whichButton; // moves given mouse button up (btn release)

- (void)dmwm:(int16_t)x andWith:(int16_t)y; // mouse wheel move

- (void)dkdn:(UInt16)key;

- (void)dkup:(UInt16)key;

- (UInt32) peek;

- (CFXCommand) waitCommand:(UInt8*)buffer
                     bytes:(size_t)toRead; // waits for a command from a client

- (void)processCmd:(UInt8*)cmd
            ofType:(CFXCommand)type
             bytes:(size_t)toSend;

@end

@protocol CFXProtocolListener <NSObject>

- (void)receive:(UInt8*)cmd
         ofType:(CFXCommand)type
     withLength:(size_t)length
     from:(CFXProtocol*)sender;
@end

#endif
