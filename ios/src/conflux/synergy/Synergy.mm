#import <map>
#import <sys/socket.h>
#import <unistd.h>
#import <netinet/in.h>
#import <pthread.h>
#import "Foundation/Foundation.h"
#import "Synergy.h"
#import "Protocol.h"
#import "Mouse.h"

typedef struct {
    int _state;
    int _targetWidth, _targetHeight;
    int _remoteCursorX, _remoteCursorY;
    int _currentCursorX, _currentCursorY;
    int _dmmvSeq, _dmmvFilter;
    double _xProjection, _yProjection;
    char name[256];
} CFXClientContext;

@interface CFXSynergy()

/**
 Holds the currently active client.
 */
@property CFXProtocol* _active;

- (void)_addClient:(id<CFXSocket>)clientSocket;

- (void)_setupSocket:(id<CFXSocket>)socket;

- (bool)_loaded;

@end

typedef std::map<CFXProtocol*, CFXClientContext*> CFXClients;

@implementation CFXSynergy
{
    CFXClients _clients;
    pthread_mutex_t _clientsLock;
    id<CFXSocket> _socket;
    id<CFXSynergyListener> _listener;
    int _sourceWidth, _sourceHeight;
    BOOL _loaded, _noTimer;
}

- (id)init
{
    if(self = [super init]) {
        self->_socket = nil;
        self->_clientsLock = PTHREAD_MUTEX_INITIALIZER;
        return self;
    } else {
        return nil;
    }
}

- (void)activate:(const char *)screenName
{
    pthread_mutex_lock(&self->_clientsLock);
    for(CFXClients::iterator i = self->_clients.begin(); i != self->_clients.end(); i++) {
        if(strcmp(screenName, i->second->name) == 0) {
            self._active = i->first;
            NSLog(@"II SYNERGY ACTIVATE: %s ACTIVATED", screenName);
            break;
        }
    }
    pthread_mutex_unlock(&self->_clientsLock);
}

- (void)load:(CFXPoint *)sourceResolution
{
    [self load:sourceResolution
          with:[[CFXFoundationSocket alloc] init]];
}

- (void)load:(CFXPoint *)sourceResolution
        with:(id<CFXSocket>)socket

{
    self->_sourceWidth = sourceResolution.x;
    self->_sourceHeight = sourceResolution.y;
    
    self->_socket = socket;
    [self _setupSocket:self->_socket];
    
    self->_loaded = YES;
    
    NSLog(@"II SYNERGY LOAD: initialized source res with: %d, %d", self->_sourceWidth, self->_sourceHeight);
    NSLog(@"II SYNERGY LOAD: after init, clients map has %lu elements", self->_clients.size());
}

- (void)finalize
{
    [self unload];
    pthread_mutex_destroy(&self->_clientsLock);
}

- (void)unload
{
    if(self->_loaded) {

        self->_loaded = NO;
        for(CFXClients::iterator i = self->_clients.begin(); i != self->_clients.end(); i++) {
            [i->first unload];
            free(i->second);
        }
        [self->_socket disconnect];        
        self._active = nil;
        self->_socket = nil;

    }
}

- (void) disableCalvTimer
{
    self->_noTimer = true;
}

- (bool)_loaded
{
    return self->_loaded;
}

- (void)changeOrientation
{
    double tmp = self->_sourceWidth;
    self->_sourceWidth = self->_sourceHeight;
    self->_sourceHeight = tmp;
    
    CFXClientContext* ctx = [self _getActiveCtx];
    if(self->_loaded && ctx) {
        NSLog(@"II SYNERGY CHANGEORIENTATION %f, %f", ctx->_xProjection, ctx->_yProjection);
        pthread_mutex_lock(&self->_clientsLock);
        [self _updateProjection];
        pthread_mutex_unlock(&self->_clientsLock);
    }
}

-(void)keyStroke:(UInt16)character
{
    if(!self->_loaded || !self._active) {
        return;
    }
    [self._active dkdn: character];
    [self._active dkup: character];
}

- (void)click:(CFXMouseButton)whichButton
{
    if(!self->_loaded || !self._active) {
        return;
    }
    [self._active dmdn: whichButton];
    [self._active dmup: whichButton];
}

- (void)doubleClick:(CFXMouseButton)whichButton
{
    if(!self->_loaded || !self._active) {
        return;
    }
    [self click: whichButton];
    [self click: whichButton];
}

- (void)beginMouseMove:(CFXPoint *)coordinates
{
    if(!self->_loaded || !self._active) {
        return;
    }
    
    CFXClientContext* ctx = [self _getActiveCtx];
    ctx->_currentCursorX = coordinates.x;
    ctx->_currentCursorY = coordinates.y;
}

- (void)mouseMove:(CFXPoint*)coordinates
{
    if(!self->_loaded || !self._active) {
        return;
    }
    
    CFXClientContext* ctx = [self _getActiveCtx];
    
    if(ctx->_dmmvSeq++ % ctx->_dmmvFilter) {
        // this is done to avoid flooding client.
        return;
    }
    double projectedDeltaX = (coordinates.x - ctx->_currentCursorX) * ctx->_xProjection;
    double projectedDeltaY = (coordinates.y - ctx->_currentCursorY) * ctx->_yProjection;
    double projectedX = ctx->_remoteCursorX + projectedDeltaX;
    double projectedY = ctx->_remoteCursorY + projectedDeltaY;
    
    
    CFXPoint* projected = [[CFXPoint alloc] initWith:projectedX > 0 ? projectedX : 0
                                             andWith:projectedY > 0 ? projectedY : 0];
    
    //NSLog(@"II SYNERGY MOUSEMOVE: (%f, %f) rc(%d, %d) pj(%d, %d)", projectedDeltaX, projectedDeltaY,
    //      ctx->_remoteCursorX, ctx->_remoteCursorY, projected.x, projected.y);
    
    [self._active dmov: projected];
    
    ctx->_remoteCursorX = projected.x;
    ctx->_remoteCursorY = projected.y;
    ctx->_currentCursorX = coordinates.x;
    ctx->_currentCursorY = coordinates.y;
}

- (void)receive:(UInt8*)cmd
         ofType:(CFXCommand)type
     withLength:(size_t)length
     from:(CFXProtocol *)sender
{
    if(!self->_loaded) {
        return;
    }
    
    [self _processPacket:cmd ofType:type bytes:length from:sender];
}

- (void)receive:(CFXSocketEvent)event
     fromSender:(id<CFXSocket>)socket
    withPayload:(void *)data
{
    if(!self->_loaded) {
        return;
    }
    
    if(event == kCFXSocketConnected) {
        NSLog(@"II SYNERGY RECEIVE: got socket connected event");
        id<CFXSocket> client = (__bridge id<CFXSocket>)data;
        [self _addClient:client];
    }
}

- (void)_updateProjection
{
    CFXClientContext* ctx = [self _getActiveCtxUnsafe];
    if(ctx) {
        ctx->_xProjection = (double)ctx->_targetWidth / (double)self->_sourceWidth;
        ctx->_yProjection = (double)ctx->_targetHeight / (double)self->_sourceHeight;
    }
}

- (void)_addClient:(id<CFXSocket>)clientSocket
{
    
    CFXProtocol* _protocol = [[CFXProtocol alloc] initWithSocket: clientSocket
                                                     andListener: self];
    
    CFXClientContext* ctx = (CFXClientContext*)malloc(sizeof(CFXClientContext));
    ctx->_state = 0;
    ctx->_dmmvFilter = 1;
    ctx->_targetWidth = 1280;
    ctx->_targetHeight = 800;
    ctx->_remoteCursorX = ctx->_remoteCursorY = 1;
    
    pthread_mutex_lock(&self->_clientsLock);
    NSLog(@"II SYNERGY ADDCLIENT: %lu / %d", self->_clients.size(), [_protocol idTag]);
    self->_clients[_protocol] = ctx;
    if(!self._active) {
        self._active = _protocol;
        [self _updateProjection];
    }
    pthread_mutex_unlock(&self->_clientsLock);
    
    [_protocol hail];
}

- (void)_processPacket:(UInt8*)buffer
                ofType:(CFXCommand)type
                 bytes:(size_t)numBytes
                  from:(CFXProtocol*)sender
{
    //NSLog(@"(%d) II: SYNERGY PROCESSPACKET: IN", [sender idTag]);
    CFXClientContext* ctx = self->_clients[sender];
    
    if(!ctx) {
        NSLog(@"WW SYNERGY PROCESSPACKET: got command from unknown sender: %d", [sender idTag]);
        return;
    }
    
    // process packet data
    switch(type) {
        case HAIL: [self _processHailResponse:buffer bytes:numBytes context:ctx]; break;
        case DINF: [self _processDinf: buffer bytes:numBytes context:ctx]; break;
        case TERM: [self _terminate: sender]; return;
        default:break;
    }
    
    //NSLog(@"(%d) II: SYNERGY PROCESSPACKET: type %u, state %u, nbytes: %lu", [sender idTag], type, ctx->_state, numBytes);
    
    // reply to client
    switch(ctx->_state) {
        case 0:
            ctx->_state = 1;
            
            [sender qinf];
            break;
        case 1:
            [sender ciak];
            [sender crop];
            [sender dsop];
            
            ctx->_state = 2;
            if(!self->_noTimer) {
                [sender runTimer];
            }
            break;
        case 2:
        {
            [sender cinn: [[CFXPoint alloc] initWith:ctx->_remoteCursorX
                                                   andWith:ctx->_remoteCursorY]];
            ctx->_state = 3;
            break;
        }
        default: break;
    }
    
    //NSLog(@"(%d) II: SYNERGY PROCESSPACKET: OUT", [sender idTag]);
}

- (void)ii
{
    NSLog(@">>%lu", self->_clients.size());
}

- (void)_terminate:(CFXProtocol*)sender
{
        CFXClients::const_iterator i = self->_clients.find(sender);
    
        if(i != self->_clients.end()) {
            NSLog(@"II SYNGERGY TERMINATE: (%d)", [sender idTag]);
            CFXClientContext* ctx = i->second;
            NSLog(@"II SYNERGY TERMINATE: %lu total clients left. P is %d.", self->_clients.size(), [i->first idTag]);
            pthread_mutex_lock(&self->_clientsLock);
            self->_clients.erase(i);
            pthread_mutex_unlock(&self->_clientsLock);
            if(self._active == sender) {
                if(self->_clients.size() > 0) {
                    self._active = self->_clients.begin()->first;
                    NSLog(@"II SYNERGY TERMINATE: (%d) ACTIVATED", [self._active idTag]);
                } else {
                    self._active = nil;
                }
            }
            
            [self->_listener receive:kCFXSynergyScreenLost with:ctx->name];
            free(ctx);
        }
}

- (void)_processHailResponse:(UInt8 *)buffer
                       bytes:(size_t)numBytes
                     context:(CFXClientContext*)ctx
{
    NSLog(@"Received hail response: %lu bytes", numBytes);
    memset(ctx->name, 0, sizeof(ctx->name));
    strncpy(ctx->name, (const char*)buffer + 15, numBytes - 15);
    
    if(self->_listener) {
        [self->_listener receive:kCFXSynergyNewScreen with:ctx->name];
    }
}

- (void)_processDinf:(UInt8 *)buffer
                bytes:(size_t)numBytes
             context:(CFXClientContext*)ctx
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
    NSLog(@"II SYNERGY PROCESSDINF: Info received: tX: %d, tY: %d, cX: %d, cy: %d",
           targetWidth, targetHeight, remoteCursorX, remoteCursorY);
    ctx->_targetWidth = targetWidth;
    ctx->_targetHeight = targetHeight;
    ctx->_remoteCursorX = remoteCursorX;
    ctx->_remoteCursorY = remoteCursorY;
}

- (void)registerListener:(id<CFXSynergyListener>)listener
{
    self->_listener = listener;
}

- (void)_setupSocket:(id<CFXSocket>)socket
{
    [socket registerListener:self];
    [socket listen:24800];
}

-(CFXClientContext*)_getActiveCtxUnsafe
{
    if(!self._active) {
        return NULL;
    }
    
    return self->_clients[self._active];
}

-(CFXClientContext*)_getActiveCtx
{
    pthread_mutex_lock(&self->_clientsLock);
    CFXClientContext* ctx = [self _getActiveCtxUnsafe];
    pthread_mutex_unlock(&self->_clientsLock);
    return ctx;
}
@end
