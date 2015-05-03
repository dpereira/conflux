#import <Foundation/Foundation.h>
#import "Point.h"

extern "C" {
@interface CFXPoint()
@end

@implementation CFXPoint

-(id)initWith:(UInt16)x
          andWith:(UInt16)y
{
    if(self = [super init]) {
        self.x = x;
        self.y = y;
        return self;
    } else {
        return nil;
    }
}

@end
    
}
