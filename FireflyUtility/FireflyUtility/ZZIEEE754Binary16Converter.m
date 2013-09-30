//
//  ZZIEEE754Binary16Converter.m
//  UploadCenter
//
//  Created by Denis Bohm on 6/4/09.
//

#import "ZZIEEE754Binary16Converter.h"

@implementation ZZIEEE754Binary16Converter

+ (float) toFloat: (int) bits {
	if (bits == 0) {
		return 0.0f;
	}
	
	int e = (((bits >> 10) & 0x1f) - 15) + 127;
	UInt32 bits32 = ((bits & 0x8000) << 16) | (e << 23) | ((bits & 0x3ff) << 13);

	CFSwappedFloat32 value;
	if (CFByteOrderGetCurrent() == CFByteOrderLittleEndian) {
		value.v = CFSwapInt32(bits32);
	} else {
		value.v = bits32;
	}
	float v = CFConvertFloat32SwappedToHost(value);
	return v;
}

+ (int) toBits: (float) value {
	if (value == 0.0f) {
		return 0;
	}
	
	UInt32 bits32;
	if (CFByteOrderGetCurrent() == CFByteOrderLittleEndian) {
		bits32 = CFSwapInt32(CFConvertFloat32HostToSwapped(value).v);
	} else {
		bits32 = CFConvertFloat32HostToSwapped(value).v;
	}
	int e = ((bits32 >> 23) & 0xff) - 127 + 15;
	return ((bits32 >> 16) & 0x8000) | ((e << 10) & 0x7c00) | ((bits32 >> 13) & 0x03ff);
}

@end
