//
//  FDCrypto.m
//  FireflyDevice
//
//  Created by Denis Bohm on 9/15/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import "FDCrypto.h"

#include <CommonCrypto/CommonCryptor.h>
#include <CommonCrypto/CommonDigest.h>

@implementation FDCrypto

+ (NSData *)sha1:(NSData *)data
{
    NSMutableData *digest = [NSMutableData data];
    digest.length = 20;
    CC_SHA1([data bytes], (CC_LONG)[data length], (uint8_t *)digest.bytes);
    return digest;
}

+ (NSData *)hash:(NSData *)key iv:(NSData *)iv data:(NSData *)data
{
    NSMutableData *out = [NSMutableData data];
    out.length = data.length;
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                          kCCAlgorithmAES128, 0,
                                          key.bytes, kCCKeySizeAES128,
                                          iv.bytes,
                                          data.bytes, data.length,
                                          (void *)out.bytes, out.length,
                                          &numBytesEncrypted);
    if (cryptStatus != kCCSuccess) {
        @throw [NSException exceptionWithName:@"CCCryptError"
                                       reason:@"CCCrypt error"
                                     userInfo:nil];
    }
    return [out subdataWithRange:NSMakeRange(out.length - 20, 20)];
}

static uint8_t defaultHashKeyBytes[] = {0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f};

static uint8_t defaultHashIVBytes[] = {0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13};

+ (NSData *)hash:(NSData *)data
{
    NSData *key = [NSData dataWithBytes:defaultHashKeyBytes length:sizeof(defaultHashKeyBytes)];
    NSData *iv = [NSData dataWithBytes:defaultHashIVBytes length:sizeof(defaultHashIVBytes)];
    return [FDCrypto hash:key iv:iv data:data];
}

@end
