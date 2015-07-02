
#import <Foundation/Foundation.h>
#import "MockSocket.h"

@interface CFXMockSocket()

@end


#define MAX_SENT_RECORDED 1024
#define MAX_RECV_PLAYED_BACK 1024

@implementation CFXMockSocket {
    CFXParameters _sent[MAX_SENT_RECORDED];
    CFXParameters _rcvd[MAX_RECV_PLAYED_BACK];
    id<CFXSocketListener> _listener;
    int _sentCount, _rcvdCount, _recordedCount, _poppedCount;
}

- (id)init
{
    if(self = [super init]) {
        self->_listener = nil;
        [self resetRecorder];
        return self;
    } else {
        return nil;
    }
}

- (void)finalize
{
    for(int i = 0; i < self->_sentCount; i++) {
        free(self->_sent[i].buffer);
    }

    for(int i = 0; i < self->_recordedCount; i++) {
        free(self->_rcvd[i].buffer);
    }
    
    [super finalize];
}

- (size_t)saveTo:(CFXParameters*)storage
          buffer:(const UInt8*)data
           bytes:(size_t)howMany
          offset:(int)index
{
    UInt8* bufferCopy = (UInt8*)malloc(howMany);
    memcpy(bufferCopy, data, howMany);
    storage[index].buffer = bufferCopy;
    storage[index].bytes = howMany;
    return howMany;
}

-(void)recordWithHeader:(const UInt8 *)bytes bytes:(int)howMany {
    UInt8 header[] = {0x00, 0x00, 0x00, static_cast<UInt8>(howMany) };
    [self record:header bytes:sizeof(header)];
    [self record:bytes bytes:howMany];
}

// auxiliary methods for mocking

-(void)record:(const char *)payload {
    NSLog(@"-> %s", payload);
    [self recordWithHeader:(const UInt8 *)payload bytes:(int)strlen(payload)];
}

- (void)record:(const UInt8*)buffer
         bytes:(size_t)howMany
{
    if(self->_recordedCount >= MAX_RECV_PLAYED_BACK) {
        NSLog(@"Playback buffer is saturated");
        return;
    }
    [self saveTo:self->_rcvd buffer:buffer bytes:howMany offset:self->_recordedCount];
    self->_recordedCount += 1;
}

- (void)step
{
    NSLog(@"STEP");
    [self->_listener receive:kCFXSocketReceivedData fromSender:self withPayload:NULL];
}

- (CFXParameters*)popSent
{
    if(self->_poppedCount >= self->_sentCount) {
        return nil;
    }
    CFXParameters* popped = &self->_sent[self->_poppedCount];
    self->_poppedCount += 1;
    return popped;
}

- (void)resetRecorder
{
    self->_sentCount = 0;
    self->_rcvdCount = 0;
    self->_poppedCount = 0;
    memset(self->_sent, 0, sizeof(self->_sent));
    memset(self->_rcvd, 0, sizeof(self->_rcvd));    
}

// mocked methods


- (void) registerListener:(id<CFXSocketListener>)listener
{
    NSLog(@"Listener registered");
    self->_listener = listener;
}

- (void)listen:(UInt16)port
{}

- (void)open
{}

- (size_t)send:(const UInt8 *)buffer
         bytes:(size_t)howMany
{
    if(self->_sentCount >= MAX_SENT_RECORDED) {
        NSLog(@"Max send calls reached, dropping parameters.");
        return howMany;
    }
    
    [self saveTo:self->_sent buffer:buffer
           bytes:howMany
          offset:self->_sentCount];
    
    self->_sentCount += 1;
    NSLog(@"Send interceptor %dx", self->_sentCount);

    return howMany;
}

- (size_t)recv:(UInt8 *)buffer
         bytes:(size_t)howMany
{
    NSLog(@"RECV called %lu in %dx", howMany, self->_rcvdCount);
    if(self->_rcvdCount >= MAX_RECV_PLAYED_BACK ||
       self->_rcvdCount >= self->_recordedCount)  {
        NSLog(@"Max recv calls reached, dropping parameters.");
        return 0;
    }
    
    size_t bytes = self->_rcvd[self->_rcvdCount].bytes;
    memcpy(buffer, self->_rcvd[self->_rcvdCount].buffer, bytes);
    
    self->_rcvdCount += 1;
    
    return bytes;
}

- (void)setSocket:(int)socket
{
    NSLog(@"Set socket interceptor: with socket fd %d", socket);
}

-(size_t)peek
{
    return self->_rcvd[self->_rcvdCount].bytes;
}

- (void)disconnect
{}

@end