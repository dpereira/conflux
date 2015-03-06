#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "OCMockObject.h"
#import "OCMock.h"
#import "Socket.h"
#import "Synergy.h"

@interface ConfluxTests : XCTestCase

@end

@implementation ConfluxTests

- (void)testListening {
    id socket = OCMClassMock([CFXFoundationSocket class]);
    CFXSynergy* synergy = [CFXSynergy new];
    
    CFXPoint* resolution = [[CFXPoint alloc] initWith:320 and:240];
    [synergy load:resolution with:socket];
    
    OCMVerify([socket registerListener:[OCMArg isEqual:synergy]]);
    OCMVerify([socket listen:24800]);
}

@end
