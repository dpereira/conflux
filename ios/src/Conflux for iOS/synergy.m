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

static void handleConnect(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void* data, void* info)
{

    if(kCFSocketAcceptCallBack == type) {
        CFReadStreamRef readStream = NULL;
        CFWriteStreamRef writeStream = NULL;
        CFStreamCreatePairWithSocket(kCFAllocatorDefault, (CFSocketNativeHandle)data, &readStream, &writeStream);
        UInt8 buffer[1024];
        memset(buffer, 0, sizeof(buffer));
        CFIndex howMany = 0;
        NSLog(@"Handling connect spawned");
        while((howMany = CFReadStreamRead(readStream, buffer, sizeof(buffer))) != 0) {
            NSLog(@"Read %d bytes", (int)howMany);
        }
    }
}

@interface synergy()

@end

@implementation synergy

- (void) loop {
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
    sin.sin_port = htons(22222); /* Or a specific port */
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

}

@end
