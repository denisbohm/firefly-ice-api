//
//  ZZBinaryData.h
//  Activity
//
//  Created by Denis Bohm on 11/8/11.
//

#import <Foundation/Foundation.h>

@interface ZZBinaryData : NSObject

- (id)initWithData:(NSData *)data;
- (id)init;

- (BOOL)isEmpty;

- (int)index;
- (NSData *)data;

- (float)readFloat16;
- (void)writeFloat16:(float)value;

@end
