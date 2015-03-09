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
    id socket = MKTMockObjectAndProtocol([CFXFoundationSocket class], @protocol(CFXSocket));
    CFXSynergy* synergy = [CFXSynergy new];
    
    CFXPoint* resolution = [[CFXPoint alloc] initWith:320 and:240];
    [synergy load:resolution with:socket];
    
    [MKTVerify(socket) registerListener:synergy];
    [MKTVerify(socket) listen:24800];
}


- (void)testConnection {
    id synergySocket = MKTMockObjectAndProtocol([CFXFoundationSocket class], @protocol(CFXSocket));
    CFXSynergy* synergy = [CFXSynergy new];
 
    CFXPoint* resolution = [[CFXPoint alloc] initWith:320 and:240];
    [synergy load:resolution with:synergySocket];
 
    [MKTVerify(synergySocket) registerListener:synergy];
    [MKTVerify(synergySocket) listen:24800];
 
    id clientSocket = MKTMockObjectAndProtocol([CFXFoundationSocket class], @protocol(CFXSocket));
    
    [synergy receive:kCFXSocketReceivedData fromSender:synergySocket withPayload:(__bridge void*)clientSocket];
    
    MKTArgumentCaptor* buffer = [[MKTArgumentCaptor alloc] init];
    MKTArgumentCaptor* bytes = [[MKTArgumentCaptor alloc] init];
    [MKTVerify(clientSocket) send:[buffer capture] bytes:[bytes capture]];
    //OCMVerify([clientSocket send:[OCMArg anyPointer] bytes:(size_t)[OCMArg setToValue:OCMOCK_ANY]]);
 
}


@end
