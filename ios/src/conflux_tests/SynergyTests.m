#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "OCMock.h"
#import "Socket.h"
#import "MockSocket.h"
#import "Synergy.h"

@interface CFXSynergy()

@end

@interface SynergyTests : XCTestCase

@end

@implementation SynergyTests

// auxilliary

- (void)_recordConnectionSequence:(CFXMockSocket*)recorder
{

    UInt8 hailResponseHeader[] = {
        0x00, 0x00, 0x00, 0x17
    };
    UInt8 hailResponse[] = {
        0x53, 0x79, 0x6e, 0x65,
        0x72, 0x67, 0x79, 0x00,
        0x01, 0x00, 0x05, 0x00,
        0x00, 0x00, 0x08, 0x75,
        0x6e, 0x69, 0x74, 0x5f,
        0x64, 0x65, 0x65
    };
    [recorder record:hailResponseHeader bytes:sizeof(hailResponseHeader)];
    [recorder record:hailResponse bytes:sizeof(hailResponse)];
    
    UInt8 dataResponseHeader[] = {
        0x00, 0x00, 0x00, 0x12
    };
    UInt8 dataResponse[] = {
        0x44, 0x49, 0x4e, 0x46,
        0x00, 0x00, 0x00, 0x00,
        0x05, 0x50, 0x03, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00
    };
    [recorder record:dataResponseHeader bytes:sizeof(dataResponseHeader)];
    [recorder record:dataResponse bytes:sizeof(dataResponse)];
    
    [recorder record:"CALV"];
    [recorder record:"CNOP"];
}

// tests

- (void)testListening {
    id socket = OCMClassMock([CFXFoundationSocket class]);
    CFXSynergy* synergy = [CFXSynergy new];
    
    CFXPoint* resolution = [[CFXPoint alloc] initWith:320 and:240];
    [synergy load:resolution with:socket];
    
    OCMVerify([socket registerListener:[OCMArg isEqual:synergy]]);
    OCMVerify([socket listen:24800]);
}

- (void)testConnection {
    id synergySocket = OCMClassMock([CFXFoundationSocket class]);
    CFXSynergy* synergy = [CFXSynergy new];
    
    
    CFXPoint* resolution = [[CFXPoint alloc] initWith:320 and:240];
    [synergy load:resolution with:synergySocket];
    
    CFXMockSocket* clientSocket = [[CFXMockSocket alloc] init];
    
    [self _recordConnectionSequence:clientSocket];
    
    [synergy receive:kCFXSocketConnected fromSender:synergySocket withPayload:(__bridge void*)clientSocket];
    
    [clientSocket step];
    [clientSocket step];
    [clientSocket step];
    
    [synergy beginMouseMove:[[CFXPoint alloc] initWith:20 and:20]];
    
    [clientSocket step];
    
    for(int i = 0; i < 100; i++) {
        [synergy mouseMove:[[CFXPoint alloc ] initWith:i and:i]];
    }
}

@end
