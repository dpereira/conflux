#ifndef Conflux_for_iOS_synergy_h
#define Conflux_for_iOS_synergy_h

#import "CoreFoundation/CoreFoundation.h"
#import "Point.h"
#import "Mouse.h"
#import "Protocol.h"
#import "Socket.h"

typedef enum {
    kCFXSynergyNewScreen,
    kCFXSynergyScreenLost
} CFXSynergyEvent;

@protocol CFXSynergyListener <NSObject>

- (void)receive:(CFXSynergyEvent)event
           with:(const void*)payload;

@end

@interface CFXSynergy: NSObject <CFXProtocolListener, CFXSocketListener>

- (void) load:(CFXPoint*)sourceResolution;

- (void) load:(CFXPoint*)sourceResolution
         with:(id<CFXSocket>)socket;

- (void) unload;

- (void) keyStroke:(UInt16)key;

- (void) beginMouseMove:(CFXPoint*)coordinates;

- (void) mouseMove:(CFXPoint*)coordinates;

- (void) beginMouseScroll:(CFXPoint*)coordinates;

- (void) mouseScroll:(CFXPoint*)coordinates;

- (void) beginMouseDrag:(CFXPoint*)coordinates;

- (void) endMouseDrag:(CFXPoint*)coordinates;

- (void) doubleClick:(CFXMouseButton)whichButton;

- (void) click:(CFXMouseButton)whichButton;

- (void) changeOrientation;

- (void) disableCalvTimer; // avoids CALV timer loading altogether (for ALL clients).

- (void) registerListener:(id<CFXSynergyListener>)listener;

- (void) activate:(const char*)screenName;

@end

#endif
