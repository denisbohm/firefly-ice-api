//
//  FDFireflyIceServiceBrowser.m
//  FireflyDevice
//
//  Created by Denis Bohm on 12/21/15.
//  Copyright © 2015 Firefly Design. All rights reserved.
//

#import "FDFireflyIceServiceBrowser.h"

#import "FDFireflyIceChannelSocket.h"

#import <arpa/inet.h>
#import <netinet/in.h>
#import <sys/socket.h>

@interface FDFireflyIceServiceBrowser () <NSNetServiceBrowserDelegate, NSNetServiceDelegate>

@property NSNetServiceBrowser *serviceBrowser;
@property NSMutableArray *services;
@property NSMutableArray *dictionaries;

@end

@implementation FDFireflyIceServiceBrowser

- (id)init
{
    if (self = [super init]) {
        _serviceBrowser = [[NSNetServiceBrowser alloc] init];
        [_serviceBrowser setDelegate:self];
        _services = [NSMutableArray array];
        _dictionaries = [NSMutableArray array];
    }
    return self;
}

- (void)scan
{
    [_serviceBrowser searchForServicesOfType:@"_netclass._tcp" inDomain:@"local."];
}

- (NSMutableDictionary *)dictionaryFor:(id)object key:(NSString *)key
{
    for (NSMutableDictionary *dictionary in _dictionaries) {
        if (dictionary[key] == object) {
            return dictionary;
        }
    }
    return nil;
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
           didFindService:(NSNetService *)service
               moreComing:(BOOL)moreComing
{
    [_services addObject:service];
    service.delegate = self;
    [service resolveWithTimeout:5.0];
}

- (void)netService:(NSNetService *)service didNotResolve:(NSDictionary *)errors
{
    NSLog(@"netService:didNotResolve:");
    [_services removeObject:service];
}

- (void)netServiceDidResolveAddress:(NSNetService *)service
{
    for (NSData *data in [service addresses]) {
        struct sockaddr_in *socketAddress = (struct sockaddr_in *)[data bytes];
        int sockFamily = socketAddress->sin_family;
        if (sockFamily == AF_INET) {
            char addressBuffer[100];
            const char *addressStr = inet_ntop(sockFamily, &(socketAddress->sin_addr), addressBuffer, sizeof(addressBuffer));
            int port = ntohs(socketAddress->sin_port);
            if ((addressStr != nil) && (port != 0)) {
                NSString *address = [NSString stringWithUTF8String:addressStr];
                NSLog(@"Found service at %@:%d", address, port);
                [self discoveredService:service address:address port:port];
                break;
            }
        }
    }
    [_services removeObject:service];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
         didRemoveService:(NSNetService *)service
               moreComing:(BOOL)moreComing
{
    NSMutableDictionary *dictionary = [self dictionaryFor:service key:@"service"];
    if (dictionary == nil) {
        return;
    }
    FDFireflyIce *fireflyIce = dictionary[@"fireflyIce"];
    [_dictionaries removeObject:dictionary];
    [_delegate fireflyIceServiceBrowser:self removed:fireflyIce];
}

- (void)discoveredService:(NSNetService *)service address:(NSString *)address port:(int)port
{
    NSMutableDictionary *dictionary = [self dictionaryFor:service key:@"service"];
    if (dictionary != nil) {
        return;
    }
    
    FDFireflyIce *fireflyIce = [[FDFireflyIce alloc] init];
    
    fireflyIce.name = @"FireflyIce";
    
    FDFireflyIceChannelSocket *channel = [[FDFireflyIceChannelSocket alloc] initWithAddress:address port:port];
    [fireflyIce addChannel:channel type:@"INET"];
    dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject:service forKey:@"service"];
    [dictionary setObject:address forKey:@"address"];
    [dictionary setObject:[NSNumber numberWithInt:port] forKey:@"port"];
    [dictionary setObject:fireflyIce forKey:@"fireflyIce"];
    [_dictionaries insertObject:dictionary atIndex:0];
    
    [_delegate fireflyIceServiceBrowser:self discovered:fireflyIce];
}

@end
