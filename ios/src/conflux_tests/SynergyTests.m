#import <UIKit/UIKit.h>
#import "Socket.h"
#import "MockSocket.h"
#import "Synergy.h"

#ifdef __cplusplus
extern "C" {
#endif
    
#import <XCTest/XCTest.h>
#import "OCMock.h"
    
#ifdef __cplusplus
}
#endif

@interface CFXSynergy()

@end

@interface SynergyTests : XCTestCase

@property CFXSynergy* synergy;
@property id<CFXSocket> synergySocket;

@end

@implementation SynergyTests

// tests

- (void)setUp
{
    id socket = OCMClassMock([CFXFoundationSocket class]);
    CFXSynergy* synergy = [CFXSynergy new];
    
    self.synergy = synergy;
    self.synergySocket = socket;
}

- (void)testListening {
    CFXPoint* resolution = [[CFXPoint alloc] initWith:320 andWith:240];
    [self.synergy load:resolution with:self.synergySocket];
    
    OCMVerify([self.synergySocket registerListener:[OCMArg isEqual:self.synergy]]);
    OCMVerify([self.synergySocket listen:24800]);
}

- (void)testConnection {
    // setup mock socket and
    // a sequence of mock responses
    CFXMockSocket* clientSocket = [[CFXMockSocket alloc] init];
    
    UInt8 hailResponse[] = {
        0x53, 0x79, 0x6e, 0x65, 0x72, 0x67, 0x79, 0x00,
        0x01, 0x00, 0x05, 0x00, 0x00, 0x00, 0x08, 0x75,
        0x6e, 0x69, 0x74, 0x5f, 0x64, 0x65, 0x65
    };
    UInt8 dataResponse[] = {
        0x44, 0x49, 0x4e, 0x46, 0x00, 0x00, 0x00, 0x00,
        0x05, 0x50, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00
    };
    
    [self _record:hailResponse with:sizeof(hailResponse) in:clientSocket];
    [self _record:dataResponse with:sizeof(dataResponse) in:clientSocket];
    [self _record:"CALV" in:clientSocket];
    [self _record:"CNOP" in:clientSocket];

    // run test
    CFXPoint* resolution = [[CFXPoint alloc] initWith:320 andWith:240];
    [self.synergy load:resolution with:self.synergySocket];
    
    
    [self.synergy receive:kCFXSocketConnected
               fromSender:self.synergySocket
              withPayload:(__bridge void*)clientSocket];
    [self _assertCommandIn:[clientSocket popSent] is:"Synergy"];
    
    [clientSocket step];
    [self _assertCommandIn:[clientSocket popSent] is:"QINF"];
    
    [clientSocket step];
    [self _assertCommandIn:[clientSocket popSent] is:"CIAK"];
    [self _assertCommandIn:[clientSocket popSent] is:"CROP"];
    [self _assertCommandIn:[clientSocket popSent] is:"DSOP"];
    
    [clientSocket step];
    [self _assertCommandIn:[clientSocket popSent] is:"CINN"];
}

// auxiliary

- (void)_record:(const char*)message
             in:(CFXMockSocket*)recorder
{
    [self _record:(UInt8*)message
             with:strlen(message) * sizeof(const char)
               in:recorder
     ];
}

- (void)_record:(const UInt8*)message
           with:(size_t)bytes
             in:(CFXMockSocket*)recorder
{
    UInt8 header[] = {
        (bytes >> 24) & 0x00FF,
        (bytes >> 16) & 0x00FF,
        (bytes >> 8) & 0x00FF,
        bytes & 0x00FF
    };

    [recorder record:header bytes:sizeof(header)];
    [recorder record:message bytes:bytes];
}

- (void)_assertCommandIn:(CFXParameters*)p
                      is:(const char*)expected
{
    XCTAssertNotEqual((long)NULL, (long)p);
    XCTAssertLessThanOrEqual(strlen(expected) + SYNERGY_HEADER_LEN, p->bytes);
    XCTAssertEqual(0, memcmp(expected, (p->buffer + SYNERGY_HEADER_LEN), strlen(expected)));
}

@end
