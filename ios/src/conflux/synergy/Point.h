#ifndef Conflux_for_iOS_Point_h
#define Conflux_for_iOS_Point_h

#import <CoreFoundation/CoreFoundation.h>

@interface CFXPoint: NSObject

@property UInt16 x;
@property UInt16 y;

-(id)initWith:(UInt16) x
          and:(UInt16) y;
@end

#endif
