//
//  FDFireflyIceService.m
//  FireflyDevice
//
//  Created by Denis Bohm on 12/21/15.
//  Copyright © 2015 Firefly Design. All rights reserved.
//

#import "FDFireflyIceService.h"

#import <netinet/in.h>
#import <sys/socket.h>

@interface FDFireflyIceService () <NSNetServiceDelegate>

@property NSSocketPort *socket;
@property NSFileHandle *socketHandle;
@property struct sockaddr *address;
@property int port;
@property NSNetService *service;
@property NSMutableArray *services;

@end

@implementation FDFireflyIceService

- (BOOL)publish
{
    // get a system assigned port number
    _socket = [[NSSocketPort alloc] initWithTCPPort:0];
    if (_socket == nil) {
        NSLog(@"unexpected socket error");
        return NO;
    }
    
    _address = (struct sockaddr*)[[_socket address] bytes];
    if (_address->sa_family == AF_INET) {
        _port = ntohs(((struct sockaddr_in *)_address)->sin_port);
    } else
        if (_address->sa_family == AF_INET6) {
            _port = ntohs(((struct sockaddr_in6 *)_address)->sin6_port);
        } else {
            NSLog(@"unexpected socket family");
            return NO;
        }
    if (_port == 0) {
        NSLog(@"unexpected socket port");
        return NO;
    }
    
    _service = [[NSNetService alloc] initWithDomain:@"local." type:@"_netclass._tcp" name:@"FireflyIce" port:_port];
    if (_service == nil) {
        NSLog(@"unexpected service error");
        return NO;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectionAccepted:)
                                                 name:NSFileHandleConnectionAcceptedNotification object:nil];
    [_service setDelegate:self];
    [_service publish];
    
    return YES;
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
    NSLog(@"netService:didNotPublish:");
    for (NSString *key in errorDict) {
        NSLog(@"  %@", [errorDict valueForKey:key]);
    }
    [_services removeObject:sender];
}

- (void)netServiceDidPublish:(NSNetService *)sender
{
    [_services addObject:sender];
    _socketHandle = [[NSFileHandle alloc] initWithFileDescriptor:[_socket socket] closeOnDealloc:YES];
    
    [_socketHandle acceptConnectionInBackgroundAndNotify];
}

- (void)connectionAccepted:(NSNotification *)notification
{
    NSFileHandle *connectionHandle = [[notification userInfo] objectForKey:NSFileHandleNotificationFileHandleItem];
    
    [_delegate fireflyIceService:self connectionAccepted:connectionHandle];
}

@end
