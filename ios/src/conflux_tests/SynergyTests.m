#define HC_SHORTHAND
#define MOCKITO_SHORTHAND

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "OCHamcrest.h"
#import "OCMockito.h"
#import "Socket.h"
#import "Synergy.h"

@interface CFXSynergy()

@end

@interface SynergyTests : XCTestCase

@end

@implementation SynergyTests

- (void)testListening {
    id socket = mockObjectAndProtocol([CFXFoundationSocket class], @protocol(CFXSocket));
    CFXSynergy* synergy = [CFXSynergy new];
    
    CFXPoint* resolution = [[CFXPoint alloc] initWith:320 and:240];
    [synergy load:resolution with:socket];
    
    [MKTVerify(socket) registerListener:synergy];
    [MKTVerify(socket) listen:24800];
}

/*
- (void)testConnection {
    id synergySocket = OCMClassMock([CFXFoundationSocket class]);
    CFXSynergy* synergy = [CFXSynergy new];
    
    
    CFXPoint* resolution = [[CFXPoint alloc] initWith:320 and:240];
    [synergy load:resolution with:synergySocket];
    
    id clientSocket = OCMClassMock([CFXFoundationSocket class]);
    
    [synergy receive:kCFXSocketReceivedData fromSender:synergySocket withPayload:(__bridge void*)clientSocket];
    
    OCMVerify([clientSocket send:[OCMArg anyPointer] bytes:(size_t)[OCMArg setToValue:OCMOCK_ANY]]);
 
}
*/

@end
