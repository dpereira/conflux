//
//  Holds the implementation of methods directly related
//  with the synergy protocol
//

#import "Protocol.h"
#import <Foundation/Foundation.h>
#import <sys/socket.h>
#import <arpa/inet.h>
#import <synergy/key_types.h>

@interface  CFXProtocol()
@end


@implementation CFXProtocol
{
    id<CFXSocket> _socket;
    id<CFXProtocolListener>  _listener;
}


-(id)initWithSocket:(id<CFXSocket>)socket
        andListener:(id<CFXProtocolListener>)listener
{
    if(self = [super init]) {
        [socket registerListener:self];
        
        self->_socket = socket;
        self->_listener = listener;
        
        [socket open];
        
        return self;
    } else {
        return nil;
    }
}

- (void)unload
{
    [self->_socket disconnect];
}

-(void)hail {
    UInt8 hail[] = {0x53, 0x79, 0x6e, 0x65, 0x72, 0x67, 0x79, 0x00, 0x01, 0x00, 0x05};
    [self _writeRaw:hail bytes:sizeof(hail)];
}

-(void)qinf {
    [self _writeSimple:"QINF"];
}

-(void)ciak {
    [self _writeSimple:"CIAK"];
}

-(void)crop {
    [self _writeSimple:"CROP"];
}

-(void)dsop {
    [self _writeSimple:"DSOP"];
}

-(void)calv {
    [self _writeSimple:"CALV"];
}

-(void)cinn:(const CFXPoint *)coordinates {
    NSLog(@"Entering screen");
    UInt16 x = coordinates.x;
    UInt16 y = coordinates.y;
    const UInt8 cmd[] = {'C', 'I', 'N', 'N', (UInt8)(x >> 8), (UInt8)(x & 0x00FF), (UInt8)(y >> 8), (UInt8)(y & 0x00FF) };
    [self _writeRaw:cmd bytes:sizeof(cmd)];
    
}

-(void)dmov:(const CFXPoint *)coordinates {
    UInt16 x = coordinates.x;
    UInt16 y = coordinates.y;
    const UInt8 cmd[] = {'D','M','M','V', (UInt8)(x >> 8), (UInt8)(x & 0x00FF), (UInt8)(y >> 8), (UInt8)(y & 0x00FF)};
    [self _writeRaw:cmd bytes:sizeof(cmd)];
}

-(void)dmdn:(CFXMouseButton)whichButton {
    NSLog(@"Mouse down: %02x", whichButton);
    const UInt8 cmd[] = {'D','M','D','N', (UInt8)whichButton };
    [self _writeRaw:cmd bytes:sizeof(cmd)];
}

-(void)dmup:(CFXMouseButton)whichButton {
    NSLog(@"Mouse up: %02x", whichButton);    
    const UInt8 cmd[] = {'D','M','U','P', (UInt8)whichButton };
    [self _writeRaw:cmd bytes:sizeof(cmd)];
}

-(void)dkdn:(UInt16) key {
    NSLog(@"Key down: %02x |%c|", key, key);
    
    if(key == 10) {
        key = kKeyReturn;
    }
        
    UInt8 keyHigh = key >> 8;
    UInt8 keyLow = key & 0x00FF;

    const UInt8 cmd[] = {'D', 'K', 'D', 'N', keyHigh, keyLow, 0x00, 0x00, keyHigh, keyLow};
    [self _writeRaw:cmd bytes:sizeof(cmd)];
}

-(void)dkup:(UInt16) key {
    NSLog(@"Key up: %02x |%c|", key, key);
    UInt8 keyHigh = key >> 8;
    UInt8 keyLow = key & 0x00FF;
    const UInt8 cmd[] = {'D', 'K', 'U', 'P', 0x00, 0x00, 0x00, 0x00, keyHigh, keyLow};
    [self _writeRaw:cmd bytes:sizeof(cmd)];
}

-(void)_writeRaw:(const UInt8 *)bytes bytes:(int)howMany {
    UInt8 header[] = {0x00, 0x00, 0x00, (UInt8) howMany };
    UInt8 *buffer = (UInt8*)malloc(sizeof(header) + howMany);
    memcpy(buffer, header, sizeof(header));
    memcpy(buffer + sizeof(header), bytes, howMany);
    
    [self->_socket send:buffer bytes:sizeof(header) + howMany];
    free(buffer);
}

-(void)_writeSimple:(const char *)payload {
    NSLog(@"-> %s", payload);
    [self _writeRaw:(const UInt8 *)payload bytes:(int)strlen(payload)];
}

- (UInt32) peek {
    UInt8 headerBuffer[SYNERGY_HEADER_LEN];
    memset(headerBuffer, 0, sizeof(headerBuffer));
    [self->_socket recv:headerBuffer bytes:sizeof(headerBuffer)];
    return [self _fromQuartetTo32Bits:headerBuffer];
}

- (UInt32)_fromQuartetTo32Bits:(const UInt8 [4])quartet {
    UInt32 value = 0;
    value += quartet[0] << 24;
    value += quartet[1] << 16;
    value += quartet[2] << 8;
    value += quartet[3];
    
    return value;
}

- (CFXCommand) waitCommand:(UInt8*)buffer
                   bytes:(size_t)toRead {
    memset(buffer, 0, toRead);
    [self->_socket recv:buffer bytes:toRead];
    return [self _classify:buffer];
}

- (CFXCommand) _classify:(UInt8*) cmd {
    // Always make this match the CFXCommand
    // enum or this method will stop working properly.
    const char* commandIds[] = {
        "NONE",
        "HAIL",
        "CNOP",
        "QINF",
        "DINF",
        "CALV",
        "CIAK",
        "DSOP",
        "CROP",
        "CINN",
        "DMOV",
        "DMDN",
        "DMUP"
    };
    
    char identifier[5]; identifier[4] = 0;
    strncpy(identifier, (const char*)cmd, 4);
    
    for(int i = 0; i < sizeof(commandIds) / sizeof(char*); i++) {
        if(strcmp(identifier, commandIds[i]) == 0) {
            NSLog(@"<- %s", identifier);
            return (CFXCommand)i;
        } else if(strcmp(identifier, "Syne"/*rgy*/) == 0) { // cheating
            return HAIL;
        }
    }
    
    NSLog(@"!! unable to classify: %s", identifier);
    
    return NONE;
}

- (void)processCmd:(UInt8*)cmd
            ofType:(CFXCommand)type
             bytes:(size_t)length
{
    [self->_listener receive:cmd ofType:type withLength: length];
}

- (void)receive:(CFXSocketEvent)event
     fromSender:(id<CFXSocket>)socket
    withPayload:(void *)data
{
    size_t howMany = [self peek];
    UInt8 cmd[howMany < SYNERGY_PKTLEN_MAX ? howMany : SYNERGY_PKTLEN_MAX];
    CFXCommand type = [self waitCommand:cmd bytes:howMany];
    [self processCmd:cmd ofType:type bytes:howMany];
}

@end