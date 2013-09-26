//
//  FDFireflyIceSync.m
//  FireflyDevice
//
//  Created by Denis Bohm on 9/25/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDFireflyIce.h"
#import "FDFireflyIceChannel.h"
#import "FDFireflyIceCoder.h"
#import "FDFireflyIceSync.h"

@interface FDFireflyIceSync ()

@property NSString *site;

@end

@implementation FDFireflyIceSync

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel status:(FDFireflyIceChannelStatus)status;
{
    if (status == FDFireflyIceChannelStatusOpen) {
        [fireflyIce.coder sendGetProperties:channel properties:FD_CONTROL_PROPERTY_SITE];
    }
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel site:(NSString *)site
{
    _site = site;
    NSLog(@"device site %@", _site);
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel syncData:(NSData *)data
{
    NSLog(@"sync data for %@", _site);
    
    NSString *url = [NSString stringWithFormat:@"%@/sync", _site];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request addValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%ld", (unsigned long)data.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:data];
    
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString *type = response.MIMEType;
    if (![@"application/octet-stream" isEqual:[type lowercaseString]]) {
        NSLog(@"sync data response: %@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        return;
    }
    NSLog(@"sending sync response");
    [channel fireflyIceChannelSend:responseData];
}

@end
