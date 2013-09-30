//
//  ZZBinaryData.m
//  Activity
//
//  Created by Denis Bohm on 11/8/11.
//

#import "ZZBinaryData.h"
#import "ZZIEEE754Binary16Converter.h"

@interface ZZBinaryData () {
    NSMutableData *_data;
    int _index;
}

@end

@implementation ZZBinaryData

- (id)init
{
	return [self initWithData:[NSData data]];
}

- (id)initWithData:(NSData *)data
{
    if (self = [super init]) {
		_data = [NSMutableData dataWithData: data];
    }
    return self;
}

- (BOOL)isEmpty
{
    return _index >= [_data length];
}

- (int)index
{
    return _index;
}

- (NSData *)data
{
    return _data;
}

- (NSString *)toString
{
	NSMutableString* buffer = [[NSMutableString alloc] init];
	uint8_t* bytes = (uint8_t *) [_data bytes];
	int length = [_data length];
	for (int i = 0; i < length; ++i) {
		int byte = bytes[i] & 0xff;
		[buffer appendFormat: @" %02x", byte];
	}
	return buffer;
}

- (void)checkIndex:(int)n
{
	int ni = _index + n;
	if ((ni < 0) || (ni > [_data length])) {
		@throw [NSException
                exceptionWithName:@"PacketIndexOutOfRange"
                reason:[NSString stringWithFormat:@"packet index out of range: %@", [self toString]] userInfo: nil];
	}
}

- (float)readFloat16
{
	[self checkIndex:2];
	uint8_t* bytes = (uint8_t *) [_data bytes];
	int b1 = bytes[_index++] & 0xff;
	int b0 = bytes[_index++] & 0xff;
	int bits = (b1 << 8) | b0;
    return [ZZIEEE754Binary16Converter toFloat:bits];
}

- (void)writeFloat16:(float)value
{
	int bits = [ZZIEEE754Binary16Converter toBits:value];
	uint8_t bytes[2] = {(uint8_t) (bits >> 8), (uint8_t) bits};
	[_data appendBytes:bytes length:2];
}

@end
