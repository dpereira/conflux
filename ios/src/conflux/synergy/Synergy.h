#ifndef Conflux_for_iOS_synergy_h
#define Conflux_for_iOS_synergy_h

#import "CoreFoundation/CoreFoundation.h"
#import "Point.h"
#import "Mouse.h"
#import "Protocol.h"
#import "Socket.h"

@interface CFXSynergy: NSObject <CFXProtocolListener, CFXSocketListener>

- (void) load:(CFXPoint*)sourceResolution;

- (void) load:(CFXPoint*)sourceResolution
         with:(id<CFXSocket>)socket;

- (void) unload;

- (void) unloadTimer; // interrupts CALV timer.

- (void) keyStroke:(UInt16)key;

- (void) beginMouseMove:(CFXPoint*)coordinates;

- (void) mouseMove:(CFXPoint*)coordinates;

- (void) doubleClick:(CFXMouseButton)whichButton;

- (void) click:(CFXMouseButton)whichButton;

- (void) changeOrientation;

- (void) disableCalvTimer; // avoids CALV timer altogether.

@end

#endif
