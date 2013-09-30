//
//  ZZIEEE754Binary16Converter.h
//  UploadCenter
//
//  Created by Denis Bohm on 6/4/09.
//

#import <Foundation/Foundation.h>

@interface ZZIEEE754Binary16Converter : NSObject {

}

+ (float) toFloat: (int) bits;

+ (int) toBits: (float) value;

@end
