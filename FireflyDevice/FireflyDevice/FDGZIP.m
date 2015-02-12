//
//  FDGZIP.m
//  FireflyDevice
//
//  Created by Denis Bohm on 2/10/15.
//  Copyright (c) 2015 Firefly Design. All rights reserved.
//

#import "FDGZIP.h"

#import <zlib.h>

@implementation FDGZIP

int Compress(const unsigned char *source, unsigned int sourcelen, unsigned char** target, unsigned int *targetlen);
int Decompress(const unsigned char *source, unsigned int sourcelen, unsigned char **target, unsigned int *targetlen);

/** Buffersize for compress/decompress **/
#define INCREASE 10240

#ifndef max
#define max(x,y) ((x) > (y) ? (x) : (y))
#endif

/** Compress data by GZIP in Memory
 
 @param source Pointer to the data to be compressed
 @param sourcelen len of sourcedata
 @param target Pointer to the result. Has to be freed by 'free'
 @param targetlen Len of targetdata
 @return always 0
 **/
int Compress(const unsigned char *source, unsigned int sourcelen, unsigned char** target, unsigned int *targetlen)
{
    z_stream c_stream;
    memset(&c_stream, 0, sizeof(c_stream));
    
    int ret = 0;
    int err;
    int alloclen = max(sourcelen, INCREASE);
    
    c_stream.zalloc = NULL;
    c_stream.zfree = NULL;
    c_stream.opaque = NULL;
    
    *target = (unsigned char *) malloc(alloclen);
    
    // Initialisation, so that GZIP will be created
    if (deflateInit2(&c_stream,Z_BEST_COMPRESSION,Z_DEFLATED, 15 + 16, 8, Z_DEFAULT_STRATEGY) == Z_OK)
    {
        c_stream.next_in  = (Bytef*)source;
        c_stream.avail_in = sourcelen;
        c_stream.next_out = *target;
        c_stream.avail_out = alloclen;
        
        while (c_stream.total_in != sourcelen && c_stream.total_out < *targetlen)
        {
            err = deflate(&c_stream, Z_NO_FLUSH);
            // CHECK_ERR(err, "deflate");
            if (c_stream.avail_out == 0)
            {
                // Alloc new memory
                int now = alloclen;
                alloclen += alloclen / 10 + INCREASE;
                *target = (unsigned char *) realloc(*target, alloclen);
                c_stream.next_out = *target + now;
                c_stream.avail_out = alloclen - now;
            }
        }
        // Finish the stream
        for (;;)
        {
            err = deflate(&c_stream, Z_FINISH);
            if (err == Z_STREAM_END) break;
            if (c_stream.avail_out == 0)
            {
                // Alloc new memory
                int now = alloclen;
                alloclen += alloclen / 10 + INCREASE;
                *target = (unsigned char *) realloc(*target, alloclen);
                c_stream.next_out = *target + now;
                c_stream.avail_out = alloclen - now;
            }
            // CHECK_ERR(err, "deflate");
        }
        
        err = deflateEnd(&c_stream);
        // CHECK_ERR(err, "deflateEnd");
    }
    *targetlen = (unsigned int)c_stream.total_out;
    // free remaining memory
    *target = (unsigned char *) realloc(*target, *targetlen);
    
    return ret;
}

/** Inflate data with GZIP
 
 @param source Pointer to the compressed data
 @param sourcelen Len of compressed data
 @param target Pointer to the inflated data, has to be freed with 'free'
 @param targetlen Len of inflated data
 @return always 0
 **/
int Decompress(const unsigned char *source, unsigned int sourcelen, unsigned char **target, unsigned int *targetlen)
{
    z_stream c_stream;
    memset(&c_stream, 0, sizeof(c_stream));
    
    int err;
    int alloclen = max(sourcelen * 2, INCREASE);
    
    c_stream.zalloc = NULL;
    c_stream.zfree = NULL;
    c_stream.opaque = NULL;
    
    *target = (unsigned char *) malloc(alloclen+1);
    *targetlen = 0;
    
    if (inflateInit2(&c_stream, 15 + 16) == Z_OK)
    {
        c_stream.next_in  = (Bytef*)source;
        c_stream.avail_in = sourcelen;
        c_stream.next_out = *target;
        c_stream.avail_out = alloclen;
        
        while (c_stream.total_in != sourcelen && c_stream.total_out < *targetlen)
        {
            err = inflate(&c_stream, Z_NO_FLUSH);
            // CHECK_ERR(err, "deflate");
            if (c_stream.avail_out == 0)
            {
                // Alloc new memory
                int now = alloclen;
                alloclen += alloclen / 10 + INCREASE;
                *target = (unsigned char *) realloc(*target, alloclen+1);
                c_stream.next_out = *target + now;
                c_stream.avail_out = alloclen - now;
            }
        }
        // Finish the stream
        for (;;)
        {
            err = inflate(&c_stream, Z_FINISH);
            if (err == Z_STREAM_END) break;
            if (c_stream.avail_out == 0)
            {
                // alloc new memory
                int now = alloclen;
                alloclen += alloclen / 10 + INCREASE;
                *target = (unsigned char *) realloc(*target, alloclen+1);
                c_stream.next_out = *target + now;
                c_stream.avail_out = alloclen - now;
            }
            // CHECK_ERR(err, "deflate");
        }
        
        err = inflateEnd(&c_stream);
        // CHECK_ERR(err, "deflateEnd");
    }
    *targetlen = (unsigned int)c_stream.total_out;
    // Free remaining memory
    *target = (unsigned char *) realloc(*target, *targetlen);
    
    return 0;
}

+ (NSData *)compress:(NSData *)data
{
    unsigned char* bytes;
    unsigned int length;
    Compress([data bytes], (unsigned int)[data length], &bytes, &length);
    return [NSData dataWithBytesNoCopy: bytes length: length];
}

+ (NSData *)decompress:(NSData *)data
{
    unsigned char* bytes;
    unsigned int length;
    Decompress([data bytes], (unsigned int)[data length], &bytes, &length);
    return [NSData dataWithBytesNoCopy:bytes length:length];
}

@end
