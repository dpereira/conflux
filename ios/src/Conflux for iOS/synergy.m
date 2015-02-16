//
//  synergy.m
//  Conflux for iOS
//
//  Created by Diego Pereira on 2/1/15.
//  Copyright (c) 2015 Conflux. All rights reserved.
//

#import "synergy.h"
#include <CoreFoundation/CoreFoundation.h>
#include <sys/socket.h>
#include <netinet/in.h>
@import Foundation;

static int state = 0;

static void writeSimple(const char *payload, CFWriteStreamRef writeStream) {
    NSLog(@"Answaring: %s", payload);
    int len = strlen(payload);
    UInt8 header[] = {0x00, 0x00, 0x00, len};
    UInt8 *buffer = malloc(sizeof(header) + len);
    memcpy(buffer, header, sizeof(header));
    memcpy(buffer + sizeof(header), payload, len);
    CFWriteStreamWrite(writeStream, buffer, sizeof(header) + len);
}

static void writeBytes(UInt8* bytes, int howMany, CFWriteStreamRef writeStream) {
    CFWriteStreamWrite(writeStream, bytes, howMany);
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
            //writeSimple("HDCL", writeStream);
            //writeSimple("HDSL", writeStream);
            //writeSimple("SSCM", writeStream);
            //writeSimple("SSCS", writeStream);
            //writeSimple("XTXU", writeStream);
            //writeSimple("MDLT", writeStream);
            //writeSimple("SSCM", writeStream);
            //writeSimple("SSCS", writeStream);
            writeSimple("SSVR", writeStream);
            //writeSimple("_KFW", writeStream);
            state = 3;
            break;
        case 3: [NSThread sleepForTimeInterval: .5]; writeSimple("CALV", writeStream); break;
        default: break;
    }
}

static void sendHandshake(CFWriteStreamRef writeStream) {
    UInt8 hello[] = {0x00, 0x00, 0x00, 0x0b, 0x53, 0x79, 0x6e, 0x65, 0x72, 0x67, 0x79, 0x00, 0x01, 0x00, 0x05};
    
    CFWriteStreamWrite(writeStream, hello, sizeof(hello));
    state = 1;

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
<<<<<<< HEAD
        CFStreamCreatePairWithSocket(kCFAllocatorDefault, *(CFSocketNativeHandle*)data, &readStream, &writeStream);
        
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
            }
        }
        NSLog(@"LOOP ENDED WITH %ld", howMany);
        close((int)data);
=======
        CFStreamCreatePairWithSocket(kCFAllocatorDefault, (CFSocketNativeHandle)data, &readStream, &writeStream);
        NSLog(@"Handling connect spawned");
        if(!readStream) {
            NSLog(@"scewed up");
        }
        CFStreamClientContext ctx;
        ctx.info = 0;
        CFReadStreamSetClient(readStream, kCFStreamEventOpenCompleted, handleReadStream, &ctx);
        CFReadStreamScheduleWithRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        CFReadStreamOpen(readStream);
        NSLog(@"SCHEDULED");
>>>>>>> 26e3b0a46e70613d2a0f686098e7cb6175ed4076
    }
}

@interface synergy()

@end

@implementation synergy

- (void) loop {
    NSLog(@"LOOP starting");
    CFSocketRef myipv4cfsock = CFSocketCreate(
                                              kCFAllocatorDefault,
                                              PF_INET,
                                              SOCK_STREAM,
                                              IPPROTO_TCP,
                                              kCFSocketAcceptCallBack, handleConnect, NULL);
    CFSocketRef myipv6cfsock = CFSocketCreate(
                                              kCFAllocatorDefault,
                                              PF_INET6,
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
    
    struct sockaddr_in6 sin6;
    
    memset(&sin6, 0, sizeof(sin6));
    sin6.sin6_len = sizeof(sin6);
    sin6.sin6_family = AF_INET6; /* Address family */
    sin6.sin6_port = htons(0); /* Or a specific port */
    sin6.sin6_addr = in6addr_any;
    
    CFDataRef sin6cfd = CFDataCreate(
                                     kCFAllocatorDefault,
                                     (UInt8 *)&sin6,
                                     sizeof(sin6));
    
    CFSocketSetAddress(myipv6cfsock, sin6cfd);
    CFRelease(sin6cfd);
    
    NSLog(@"ALL BOUND");
    CFRunLoopSourceRef socketsource = CFSocketCreateRunLoopSource(
                                                                  kCFAllocatorDefault,
                                                                  myipv4cfsock,
                                                                  0);
    
    CFRunLoopAddSource(
                       CFRunLoopGetCurrent(),
                       socketsource,
                       kCFRunLoopDefaultMode);
    
    CFRunLoopSourceRef socketsource6 = CFSocketCreateRunLoopSource(
                                                                   kCFAllocatorDefault,
                                                                   myipv6cfsock,
                                                                   0);
    
    CFRunLoopAddSource(
                       CFRunLoopGetCurrent(),
                       socketsource6,
                       kCFRunLoopDefaultMode);
    
    NSLog(@"ALL DONE");

}

@end
