//
//  ZZSync.m
//  FireflyUtility
//
//  Created by Denis Bohm on 9/28/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "ZZActivityUploader.h"
#import "ZZHardwareId.h"
#import "ZZSync.h"

#import <FireflyDevice/FDBinary.h>
#import <FireflyDevice/FDFireflyIceCoder.h>

@interface ZZSync ()

@property NSString *uuid;
@property NSString *site;
@property NSString *hardwareId;
@property ZZActivityUploader *activityUploader;

@end

@implementation ZZSync

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel status:(FDFireflyIceChannelStatus)status;
{
    if (status == FDFireflyIceChannelStatusOpen) {
        _site = nil;
        _hardwareId = nil;
        [fireflyIce.coder sendGetProperties:channel properties:FD_CONTROL_PROPERTY_SITE];
    }
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel site:(NSString *)site
{
    _site = site;
    NSLog(@"device site %@", _site);
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel hardwareId:(FDFireflyIceHardwareId *)hardwareId
{
    NSMutableString *string = [NSMutableString stringWithString:@"ZM1001-1.3-"];
    NSData *unique = hardwareId.unique;
    uint8_t *bytes = (uint8_t *)unique.bytes;
    for (NSUInteger i = 0; i < unique.length; ++i) {
		uint8_t byte = bytes[i];
        [string appendFormat:@"%02X", byte];
	}
    _hardwareId = string;
    NSLog(@"device hardware id %@", _hardwareId);
}

+ (NSString*)uuid
{
    CFUUIDRef puuid = CFUUIDCreate(nil);
    CFStringRef uuidString = CFUUIDCreateString(nil, puuid);
    NSString *result = (__bridge_transfer NSString *)CFStringCreateCopy(NULL, uuidString);
    CFRelease(puuid);
    CFRelease(uuidString);
    return result;
}

- (void)configureUUID
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    _uuid = [userDefaults stringForKey:@"ZZUploaderUUID"];
    if (_uuid == nil) {
        _uuid = [NSString stringWithFormat:@"ZZUploader-3.0-%@", [ZZSync uuid]];
        [userDefaults setObject:_uuid forKey:@"ZZUploaderUUID"];
        [userDefaults synchronize];
    }
}

- (void)configureUploader
{
    [_activityUploader setUrl:[[NSURL alloc] initWithString:@"http://uploads-staging.zamzee.com/uploadservice/JSONUpload"]];
    [_activityUploader setUuid:_uuid];
    [_activityUploader setHardwareId:_hardwareId];
    [_activityUploader setActivityInterval:10.0];
    [_activityUploader open];
    [_activityUploader start];
}

#define FD_STORAGE_TYPE(a, b, c, d) (a | (b << 8) | (c << 16) | (d << 24))

#define FD_LOG_TYPE FD_STORAGE_TYPE('F', 'D', 'L', 'O')
#define FD_VMA_TYPE FD_STORAGE_TYPE('F', 'D', 'V', 'M')

- (void)syncLog:(NSString *)hardwareId binary:(FDBinary *)binary
{
    NSTimeInterval time = [binary getTime64];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    NSString *date = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:time]];
    NSString *message = [[NSString alloc] initWithData:[binary getRemainingData] encoding:NSUTF8StringEncoding];
    NSLog(@"device message %@ %@", date, message);
}

- (void)syncVMA:(NSString *)hardwareId binary:(FDBinary *)binary
{
    NSTimeInterval time = [binary getTime64];
    uint16_t interval = [binary getUInt16];
    NSUInteger n = [binary getRemainingLength] / 4; //  4 == sizeof(float32)
    for (NSUInteger i = 0; i < n; ++i) {
        float value = [binary getFloat32];
        [_activityUploader activityValue:value time:time];
        time += interval;
    }
}

- (NSData *)sync:(NSData *)data
{
    FDBinary *binary = [[FDBinary alloc] initWithData:data];
    NSData *product __unused = [binary getData:8];
    NSData *unique = [binary getData:8];
    NSString *hardwareId = [ZZHardwareId hardwareId:unique];
    uint32_t page = [binary getUInt32];
    uint16_t length = [binary getUInt16];
    uint16_t hash = [binary getUInt16];
    uint32_t type = [binary getUInt32];

    if (page == 0xfffffffe) {
        return nil; // nothing to sync
    }

    switch (type) {
        case FD_LOG_TYPE:
            [self syncLog:hardwareId binary:binary];
            break;
        case FD_VMA_TYPE:
            [self syncVMA:hardwareId binary:binary];
            break;
        default:
            return nil; // unknown type
    }

    FDBinary *response = [[FDBinary alloc] init];
    [response putUInt8:FD_CONTROL_SYNC_ACK];
    [response putUInt32:page];
    [response putUInt16:length];
    [response putUInt16:hash];
    [response putUInt32:type];
    return response.dataValue;
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel syncData:(NSData *)data
{
    NSLog(@"sync data for %@", _site);
    
    if (_uuid == nil) {
        [self configureUUID];
    }

    if ((_site == nil) || (_hardwareId == nil)) {
        return;
    }
    if (_activityUploader == nil) {
        [self configureUploader];
    }
    
    NSData *responseData = [self sync:data];
    if (responseData != nil) {
        [channel fireflyIceChannelSend:responseData];
    }
}

@end
