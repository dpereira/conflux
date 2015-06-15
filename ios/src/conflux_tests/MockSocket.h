/*
 * This is a specialized mock socket,
 * which is able to trap methods with
 * pointer type parameters, something the mock
 * libs are not able to do properly.
 */

#ifndef conflux_MockSocket_h
#define conflux_MockSocket_h

#import "Socket.h"
#import <vector>

typedef struct
{
    UInt8* buffer;
    size_t bytes;
} CFXParameters;


@interface CFXMockSocket: NSObject <CFXSocket>

- (void)record:(const UInt8*)buffer
         bytes:(size_t)howMany;

- (void) record:(const char*)payload;

- (void)step;

- (id)init;

- (CFXParameters*)popSent;

- (void) resetRecorder;

@end

#endif
