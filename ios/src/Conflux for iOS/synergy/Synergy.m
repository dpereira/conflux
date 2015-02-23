//
//  synergy.m
//  Conflux for iOS
//
//  Created by Diego Pereira on 2/1/15.
//  Copyright (c) 2015 Conflux. All rights reserved.
//


#import <sys/socket.h>
#import <netinet/in.h>
#import "Foundation/Foundation.h"
#import "Synergy.h"
#import "Protocol.h"

static int state = 0;
static CFWriteStreamRef _writeStream = NULL;
static double xProportion =  1360. / 320.;
static double yProportion = 768. / 480.;

static void writeRaw(const UInt8* bytes, int howMany, CFWriteStreamRef writeStream) {
    UInt8 header[] = {0x00, 0x00, 0x00, howMany };
    UInt8 *buffer = malloc(sizeof(header) + howMany);
    memcpy(buffer, header, sizeof(header));
    memcpy(buffer + sizeof(header), bytes, howMany);
    CFWriteStreamWrite(writeStream, buffer, sizeof(header) + howMany);
    free(buffer);
}

static void writeSimple(const char *payload, CFWriteStreamRef writeStream) {
    writeRaw(payload, strlen(payload), writeStream);
}


/*
 * Enter screen @ x, y
 */
static void cinn(UInt16 x, UInt16 y, CFWriteStreamRef writeStream) {
    NSLog(@"Entering screen");
    const UInt8 cmd[] = {(UInt8)'C', (UInt8)'I', (UInt8)'N', (UInt8)'N', x >> 8, x & 0x00FF, y >> 8, y & 0x00FF };
    writeRaw(cmd, sizeof(cmd), writeStream);
}

static void dmov(UInt16 x, UInt16 y, CFWriteStreamRef writeStream) {
    NSLog(@"Moving mouse");
    const UInt8 cmd[] = {'D','M','M','V', x >> 8, x & 0x00FF, y >> 8, y & 0x00FF};
    writeRaw(cmd, sizeof(cmd), writeStream);
}

static void click(UInt8 whichButton, CFWriteStreamRef writeStream) {
    const UInt8 downCmd[] = {'D','M','D','N', whichButton };
    const UInt8 upCmd[] = {'D','M','U','P', whichButton };
    writeRaw(downCmd, sizeof(downCmd), writeStream);
    writeRaw(upCmd, sizeof(upCmd), writeStream);
}

static void doubleClick(UInt8 whichButton, CFWriteStreamRef writeStream) {
    NSLog(@"Double clicking;");
    click(whichButton, writeStream);
    click(whichButton, writeStream);
}

static void processPacket(int numBytes, CFReadStreamRef readStream, CFWriteStreamRef writeStream) {
    NSLog(@"\t%d bytes to process", numBytes);
    UInt8 buffer[numBytes];
    memset(buffer, 0, numBytes);
    CFIndex howMany = CFReadStreamRead(readStream, buffer, numBytes);
    NSLog(@"\t%ld bytes to use as command", howMany);
    
    switch(state) {
        case 0: state = 1; break;
        case 1: writeSimple("QINF", writeStream); state = 2; break;
        case 2:
            writeSimple("CIAK", writeStream);
            writeSimple("CROP", writeStream);
            writeSimple("DSOP", writeStream);
            state = 3;
            break;
        default: break;
    }
}


static void sendHandshake(CFWriteStreamRef writeStream) {
    UInt8 hello[] = {0x00, 0x00, 0x00, 0x0b, 0x53, 0x79, 0x6e, 0x65, 0x72, 0x67, 0x79, 0x00, 0x01, 0x00, 0x05};
    
    CFWriteStreamWrite(writeStream, hello, sizeof(hello));
    state = 1;
}

static void handleReadStream(CFReadStreamRef readStream, CFStreamEventType type, void *info)
{
    UInt8 buffer[8];
    memset(buffer, 0, sizeof(buffer));
    
    if(kCFStreamEventHasBytesAvailable == type) {
        CFIndex howMany = CFReadStreamRead(readStream, buffer, sizeof(buffer));
        NSLog(@"Read %d bytes", (int)howMany);
    } else if(kCFStreamEventErrorOccurred) {
        NSLog(@"Error reading stream");
    }
    
    NSLog(@"OK");
}

static void handleConnect(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void* data, void* info)
{

    if(kCFSocketAcceptCallBack == type) {
        CFReadStreamRef readStream = NULL;
        CFWriteStreamRef writeStream = NULL;
        CFStreamCreatePairWithSocket(kCFAllocatorDefault, *(CFSocketNativeHandle*)data, &readStream, &writeStream);
        
        _writeStream = writeStream;
        
        if(!CFReadStreamOpen(readStream)) {
            NSLog(@"Failed to open read stream");
            return;
        }
        
        if(!CFWriteStreamOpen(writeStream)) {
            NSLog(@"Failed to open write stream");
            return;
        }
        
        UInt8 headerBuffer[4];
        memset(headerBuffer, 0, sizeof(headerBuffer));
        CFIndex howMany = 0, total = 0;
        NSLog(@"Handling connect spawned");
        
        sendHandshake(writeStream);
        
        int bytes = CFReadStreamHasBytesAvailable(readStream);
        NSLog(@"%d bytes on wire", bytes);
        while((howMany = CFReadStreamRead(readStream, headerBuffer, sizeof(headerBuffer))) > 0) {
            total += howMany;
            NSLog(@"Read %d bytes", (int)howMany);
            if(total == 4) {
                NSLog(@"Got 4 bytes: %02x %02x %02x %02x", headerBuffer[0], headerBuffer[1], headerBuffer[2], headerBuffer[3]);
                processPacket(headerBuffer[03], readStream, writeStream);
                total = 0;
                if(state == 3) {
                    break;
                }
            }
        }
        NSLog(@"LOOP ENDED WITH %ld", howMany);
        close((int)data);
    }
}

@interface Synergy()

@property CFXProtocol* _protocol;

@property CFSocketRef _socket;

-(id)init;

@end

@implementation Synergy

-(id)init {
    if(self = [super init]) {
        self._socket = [self _initSocket];
        self._protocol = [[CFXProtocol alloc] initWithSocket: self._socket];
        return self;
    } else {
        return nil;
    }
}


- (void) doubleClick:(UInt8) whichButton {
    doubleClick(whichButton, _writeStream);
}

- (void) mouseMove:(UInt16)x withY:(UInt16)y {
    dmov(x * xProportion, y * yProportion, _writeStream);

}

- (CFSocketRef) _initSocket {
    NSLog(@"LOOP starting");
    CFSocketRef myipv4cfsock = CFSocketCreate(
                                              kCFAllocatorDefault,
                                              PF_INET,
                                              SOCK_STREAM,
                                              IPPROTO_TCP,
                                              kCFSocketAcceptCallBack, handleConnect, NULL);
    struct sockaddr_in sin;
    
    memset(&sin, 0, sizeof(sin));
    sin.sin_len = sizeof(sin);
    sin.sin_family = AF_INET; /* Address family */
    sin.sin_port = htons(24800); /* Or a specific port */
    sin.sin_addr.s_addr= INADDR_ANY;
    
    CFDataRef sincfd = CFDataCreate(
                                    kCFAllocatorDefault,
                                    (UInt8 *)&sin,
                                    sizeof(sin));
    
    CFSocketSetAddress(myipv4cfsock, sincfd);
    CFRelease(sincfd);
    
    NSLog(@"ALL BOUND");
    CFRunLoopSourceRef socketsource = CFSocketCreateRunLoopSource(
                                                                  kCFAllocatorDefault,
                                                                  myipv4cfsock,
                                                                  0);
    
    CFRunLoopAddSource(
                       CFRunLoopGetCurrent(),
                       socketsource,
                       kCFRunLoopDefaultMode);
    
    [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(_keepAlive:) userInfo:nil repeats:YES];
    
    return myipv4cfsock;
}

-(void)_keepAlive:(NSTimer*)timer {
    if(state == 3) {
        writeSimple("CALV", _writeStream);
    }
}

@end
