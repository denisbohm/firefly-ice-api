//
//  FDDetourSource.m
//  Sync
//
//  Created by Denis Bohm on 5/3/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDDetourSource.h"

@interface FDDetourSource ()

@property NSUInteger size;
@property NSData *data;
@property NSUInteger index;
@property uint8_t sequenceNumber;

@end

@implementation FDDetourSource

- (id)initWithSize:(NSUInteger)size data:(NSData *)data
{
    if (self = [super init]) {
        _size = size;
        uint16_t length = data.length;
        uint8_t bytes[2] = {length, length >> 8};
        NSMutableData *content = [NSMutableData dataWithBytes:bytes length:sizeof(bytes)];
        [content appendData:data];
        _data = content;
    }
    return self;
}

- (NSData *)next
{
    if (_index >= _data.length) {
        return nil;
    }
    
    NSUInteger n = _data.length - _index;
    if (n > (_size - 1)) {
        n = _size - 1;
    }
    NSMutableData *subdata = [NSMutableData dataWithBytes:&_sequenceNumber length:1];
    [subdata appendData:[_data subdataWithRange:NSMakeRange(_index, n)]];
    _index += n;
    ++_sequenceNumber;
    return subdata;
}

@end
