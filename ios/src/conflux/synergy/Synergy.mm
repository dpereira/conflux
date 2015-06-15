#import <sys/socket.h>
#import <unistd.h>
#import <netinet/in.h>
#import <pthread.h>
#import "Foundation/Foundation.h"
#import "Synergy.h"
#import "Protocol.h"
#import "Mouse.h"


@interface CFXSynergy()

@property CFXProtocol* _protocol;

@property int _state;

@property NSTimer* _calvTimer;

- (void)_addClient:(id<CFXSocket>)clientSocket;

- (void)_setupSocket:(id<CFXSocket>)socket;

- (bool)_loaded;

- (bool)_timerLoaded;

@end

static void* _timerLoop(void* s)
{
    CFXSynergy* synergy = (__bridge CFXSynergy*)s;
    
    while(synergy._protocol != nil && [synergy _loaded] && [synergy _timerLoaded]) {
        [synergy._protocol calv];
        sleep(2);
    }
    
    NSLog(@"II TIMERLOOP: exiting.");
    
    return NULL;
}

@implementation CFXSynergy
{
    int _sourceWidth, _sourceHeight;
    int _targetWidth, _targetHeight;
    int _remoteCursorX, _remoteCursorY;
    int _currentCursorX, _currentCursorY;
    int _dmmvSeq, _dmmvFilter;
    double _xProjection, _yProjection;
    BOOL _loaded, _noTimer;
    pthread_t* _timerThread;
    
    id<CFXSocket> _socket;
}

- (id)init
{
    if(self = [super init]) {
        self->_socket = nil;
        return self;
    } else {
        return nil;
    }
}

- (void)load:(CFXPoint *)sourceResolution
{
    [self load:sourceResolution
          with:[[CFXFoundationSocket alloc] init]];
}

- (void)load:(CFXPoint *)sourceResolution
        with:(id<CFXSocket>)socket

{
    self->_dmmvFilter = 1;
    self._calvTimer = nil;
    self->_sourceWidth = sourceResolution.x;
    self->_sourceHeight = sourceResolution.y;
    self->_targetWidth = 1280;
    self->_targetHeight = 800;
    self->_remoteCursorX = self->_remoteCursorY = 1;
    [self _updateProjection];
    
    self->_socket = socket;
    [self _setupSocket:self->_socket];
    
    self->_loaded = YES;
    
    NSLog(@"II SYNERGY LOAD: initialized source res with: %d, %d", self->_sourceWidth, self->_sourceHeight);
}

- (void)finalize
{
    [self unload];
}

- (void)unload
{
    if(self->_loaded) {
        [self unloadTimer];
        self->_loaded = NO;
        [self._protocol unload];
        [self->_socket disconnect];        
        self._protocol = nil;
        self->_socket = nil;

    }
}

// Convenience method used to disable
// timer in situations where we don't want
// it to run, such as unit testing.
- (void)unloadTimer
{
    if(self->_timerThread) {
        pthread_t timerThread = *self->_timerThread;
        free(self->_timerThread);
        self->_timerThread = NULL;
        pthread_join(timerThread, NULL);
    }
}

- (void) disableCalvTimer
{
    self->_noTimer = true;
}

- (bool)_timerLoaded
{
    return self->_timerThread != NULL;
}

- (bool)_loaded
{
    return self->_loaded;
}

- (void)changeOrientation
{
    if(self->_loaded) {
        NSLog(@"II SYNERGY CHANGEORIENTATION %f, %f", self->_xProjection, self->_yProjection);
        double tmp = self->_sourceWidth;
        self->_sourceWidth = self->_sourceHeight;
        self->_sourceHeight = tmp;
        [self _updateProjection];
    }
}

-(void)keyStroke:(UInt16)character
{
    if(!self->_loaded) {
        return;
    }
    [self._protocol dkdn: character];
    [self._protocol dkup: character];
}

- (void)click:(CFXMouseButton)whichButton
{
    if(!self->_loaded) {
        return;
    }
    [self._protocol dmdn: whichButton];
    [self._protocol dmup: whichButton];
}

- (void)doubleClick:(CFXMouseButton)whichButton
{
    if(!self->_loaded) {
        return;
    }
    [self click: whichButton];
    [self click: whichButton];
}

- (void)beginMouseMove:(CFXPoint *)coordinates
{
    if(!self->_loaded) {
        return;
    }
    self->_currentCursorX = coordinates.x;
    self->_currentCursorY = coordinates.y;
}

- (void)mouseMove:(CFXPoint*)coordinates
{
    if(!self->_loaded) {
        return;
    }
    
    if(self->_dmmvSeq++ % self->_dmmvFilter) {
        // this is done to avoid flooding client.
        return;
    }
    double projectedDeltaX = (coordinates.x - self->_currentCursorX) * self->_xProjection;
    double projectedDeltaY = (coordinates.y - self->_currentCursorY) * self->_yProjection;
    double projectedX = self->_remoteCursorX + projectedDeltaX;
    double projectedY =self->_remoteCursorY + projectedDeltaY;
    
    
    CFXPoint* projected = [[CFXPoint alloc] initWith:projectedX > 0 ? projectedX : 0
                                             andWith:projectedY > 0 ? projectedY : 0];
    
    NSLog(@"II SYNERGY MOUSEMOVE: (%f, %f) rc(%d, %d) pj(%d, %d)", projectedDeltaX, projectedDeltaY,
          self->_remoteCursorX, self->_remoteCursorY, projected.x, projected.y);
    
    [self._protocol dmov: projected];
    
    self->_remoteCursorX = projected.x;
    self->_remoteCursorY = projected.y;
    self->_currentCursorX = coordinates.x;
    self->_currentCursorY = coordinates.y;
}

- (void)receive:(UInt8*)cmd
         ofType:(CFXCommand)type
     withLength:(size_t)length
{
    if(!self->_loaded) {
        return;
    }
    
    [self _processPacket:cmd ofType:type bytes:length];
}

- (void)receive:(CFXSocketEvent)event
     fromSender:(id<CFXSocket>)socket
    withPayload:(void *)data
{
    if(!self->_loaded) {
        return;
    }
    
    if(event == kCFXSocketConnected) {
        NSLog(@"II SYNERGY: got socket connected event");
        id<CFXSocket> client = (__bridge id<CFXSocket>)data;
        [self _addClient:client];
    }
}

- (void)_updateProjection
{
    self->_xProjection = (double)self->_targetWidth / (double)self->_sourceWidth;
    self->_yProjection = (double)self->_targetHeight / (double)self->_sourceHeight;
}

- (void)_addClient:(id<CFXSocket>)clientSocket
{
    if(self._protocol != nil) {
        [self._protocol unload];
    }
    
    self._state = 0;
    
    self._protocol = [[CFXProtocol alloc] initWithSocket: clientSocket
                                             andListener: self];
    
    [self._protocol hail];
}

- (void)_processPacket:(UInt8*)buffer
                ofType:(CFXCommand)type
                 bytes:(size_t)numBytes
{
    // process packet data
    switch(type) {
        case DINF: [self _processDinf: buffer bytes:numBytes]; break;
        default:break;
    }
    
    NSLog(@"II: SYNERGY PROCESSPACKET: type %u, state %u, nbytes: %lu",type, self._state, numBytes);
    
    // reply to client
    switch(self._state) {
        case 0:
            if(self._calvTimer != nil) {
                [self._calvTimer invalidate];
                self._calvTimer = nil;
            }
            self._state = 1;
            
            [self._protocol qinf];
            break;
        case 1:
            [self._protocol ciak];
            [self._protocol crop];
            [self._protocol dsop];
            
            self._state = 2;
            [self _runTimer];
            break;            
        case 2:
            [self._protocol cinn: [[CFXPoint alloc] initWith:self->_remoteCursorX
                                                     andWith:self->_remoteCursorY]];
            self._state = 3;
            
            break;
        default: break;
    }
}

- (void)_processDinf:(UInt8 *)buffer
                bytes:(size_t)numBytes
{
    if(numBytes < 18) {
        NSLog(@"EE DINF response expected at least 18 bytes. Got %zu. Skipping packet.", numBytes);
        return;
    }
    
    // client info response
    UInt16 targetWidth = (buffer[8] << 8)+ buffer[9];
    UInt16 targetHeight = (buffer[10] << 8) + buffer[11];
    UInt16 remoteCursorX = (buffer[14] << 8) + buffer[15];
    UInt16 remoteCursorY = (buffer[16] << 8) + buffer[17];
    NSLog(@"!! Info received: tX: %d, tY: %d, cX: %d, cy: %d",
           targetWidth, targetHeight, remoteCursorX, remoteCursorY);
    self->_targetWidth = targetWidth;
    self->_targetHeight = targetHeight;
    self->_remoteCursorX = remoteCursorX;
    self->_remoteCursorY = remoteCursorY;
}

- (void)_setupSocket:(id<CFXSocket>)socket
{
    [socket registerListener:self];
    [socket listen:24800];
}

- (void)_keepAlive:(NSTimer*)timer
{
    if(self._protocol != nil) {
        [self._protocol calv];
    }
}

- (void)_runTimer
{
    if(self->_noTimer) {
        return;
    }
    
    pthread_t thread;
    pthread_attr_t attributes;
    
    if(pthread_attr_init(&attributes) != 0) {
        NSLog(@"EE Failed to initalize thread attributes");
    }
    
    pthread_create(&thread, &attributes, &_timerLoop, (__bridge void*)self);
    self->_timerThread = (pthread_t*)malloc(sizeof(thread));
    memcpy(self->_timerThread, &thread, sizeof(thread));
}

@end
