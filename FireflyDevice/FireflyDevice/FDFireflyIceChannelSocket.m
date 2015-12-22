//
//  FDFireflyIceChannelSocket.m
//  FireflyDevice
//
//  Created by Denis Bohm on 12/19/15.
//  Copyright © 2015 Firefly Design. All rights reserved.
//

#import <FireflyDevice/FDFireflyIceChannelSocket.h>

#import <FireflyDevice/FDDetour.h>
#import <FireflyDevice/FDDetourSource.h>
#import <FireflyDevice/FDFireflyDeviceLogger.h>

#import <arpa/inet.h>
#import <netinet/in.h>
#import <sys/socket.h>

@interface FDFireflyIceChannelSocket () <NSNetServiceDelegate>

@property FDFireflyIceChannelStatus status;
@property FDDetour *detour;
@property NSString *address;
@property int port;
@property NSFileHandle *fileHandle;
@property NSMutableData *data;

@end

@implementation FDFireflyIceChannelSocket

@synthesize log;

- (id)initWithAddress:(NSString *)address port:(int)port
{
    if (self = [super init]) {
        _detour = [[FDDetour alloc] init];
        _address = address;
        _port = port;
        _data = [NSMutableData data];
    }
    return self;
}

- (NSString *)name
{
    return @"INET";
}

- (void)open
{
    struct sockaddr_in addr;
    bzero(&addr, sizeof(struct sockaddr_in));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = inet_addr([_address UTF8String]);
    addr.sin_port = htons(_port);
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd < 0) {
        NSLog(@"socket error");
        return;
    }
    int result = connect(fd, (struct sockaddr *)&addr, sizeof(addr));
    if (result < 0) {
        close(fd);
        NSLog(@"connect error");
        return;
    }
    
    _fileHandle =[[NSFileHandle alloc] initWithFileDescriptor:fd];
    __weak FDFireflyIceChannelSocket *this = self;
    _fileHandle.readabilityHandler = ^(NSFileHandle *handle) {
        NSData *data = [NSData dataWithData:[handle availableData]];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [this received:data];
        });
    };
    
    self.status = FDFireflyIceChannelStatusOpening;
    if ([_delegate respondsToSelector:@selector(fireflyIceChannel:status:)]) {
        [_delegate fireflyIceChannel:self status:self.status];
    }
    self.status = FDFireflyIceChannelStatusOpen;
    if ([_delegate respondsToSelector:@selector(fireflyIceChannel:status:)]) {
        [_delegate fireflyIceChannel:self status:self.status];
    }
}

- (void)close
{
    close(_fileHandle.fileDescriptor);
    _fileHandle.readabilityHandler = nil;
    
    [_detour clear];
    self.status = FDFireflyIceChannelStatusClosed;
    if ([_delegate respondsToSelector:@selector(fireflyIceChannel:status:)]) {
        [_delegate fireflyIceChannel:self status:self.status];
    }
}

- (void)received:(NSData *)data
{
    [_data appendData:data];
    while (_data.length >= 64) {
        NSData *packet = [_data subdataWithRange:NSMakeRange(0, 64)];
        [_data replaceBytesInRange:NSMakeRange(0, 64) withBytes:nil length:0];
        [_detour detourEvent:packet];
        if (_detour.state == FDDetourStateSuccess) {
            if ([_delegate respondsToSelector:@selector(fireflyIceChannelPacket:data:)]) {
                [_delegate fireflyIceChannelPacket:self data:_detour.data];
            }
            [_detour clear];
        } else
            if (_detour.state == FDDetourStateError) {
                if ([_delegate respondsToSelector:@selector(fireflyIceChannel:detour:error:)]) {
                    [_delegate fireflyIceChannel:self detour:_detour error:_detour.error];
                }
                [_detour clear];
            }
    }
}

- (void)fireflyIceChannelSend:(NSData *)data
{
    FDDetourSource *source = [[FDDetourSource alloc] initWithSize:64 data:data];
    NSData *subdata;
    while ((subdata = [source next]) != nil) {
        if (subdata.length < 64) {
            NSMutableData *paddedData = [NSMutableData dataWithData:subdata];
            paddedData.length = 64;
            subdata = paddedData;
        }
        @try {
            [_fileHandle writeData:subdata];
        } @catch (NSException *e) {
            NSLog(@"writeData exception");
        }
    }
}

@end