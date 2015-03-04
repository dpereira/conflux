#ifndef Conflux_for_iOS_synergy_h
#define Conflux_for_iOS_synergy_h

#import <CoreFoundation/CoreFoundation.h>
#import "Point.h"
#import "Mouse.h"
#import "Protocol.h"

@interface CFXSynergy: NSObject <CFXProtocolListener>

- (void) load:(CFXPoint*)sourceResolution;

- (void) unload;

- (void) beginMouseMove:(CFXPoint*)coordinates;

- (void) mouseMove:(CFXPoint*)coordinates;

- (void) doubleClick:(kCFXMouseButton)whichButton;

- (void) click:(kCFXMouseButton)whichButton;

- (void) changeOrientation;

@end

#endif
