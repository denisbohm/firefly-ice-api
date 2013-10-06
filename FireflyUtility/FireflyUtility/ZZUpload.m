//
//  ZZUpload.m
//  FireflyUtility
//
//  Created by Denis Bohm on 10/5/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "ZZGZIP.h"
#import "ZZUpload.h"

@interface ZZUpload () <NSURLConnectionDelegate>

@property NSURLConnection *connection;
@property NSMutableData *connectionData;

@end

@implementation ZZUpload

- (id)init
{
    if (self = [super init]) {
        _username = @"firefly";
        _password = @"design";
        UIDevice *device = [UIDevice currentDevice];
        _platform = [NSString stringWithFormat:@"%@ %@", [device systemName], [device systemVersion]];
        _revision = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] intValue];
    }
    return self;
}

- (BOOL)isConnectionOpen
{
    return _connection != nil;
}

- (NSURL *)urlForSite:(NSString *)site
{
    // !!! transform http://zamzee.com to http://uploads.zamzee.com/uploadservice/JSONUpload?
    return [NSURL URLWithString:@"http://uploads.zamzee.com/uploadservice/JSONUpload"];
}

- (void)post:(NSString *)site hardwareId:(NSString *)hardwareId time:(NSTimeInterval)time interval:(NSTimeInterval)interval vmas:(NSArray *)vmas backlog:(NSUInteger)backlog
{
    if (_connection != nil) {
        @throw [NSException exceptionWithName:@"ConnectionAlreadyOpen" reason:@"connection already open" userInfo:nil];
    }
    
	NSMutableString* content = [NSMutableString stringWithString:@"{"];
    [content appendFormat:@"\"username\":\"%@\",", _username];
    [content appendFormat:@"\"password\":\"%@\",", _password];
    [content appendFormat:@"\"platform\":\"%@\",", _platform];
    [content appendFormat:@"\"revision\":%u,", _revision];
    [content appendFormat:@"\"uuid\":\"%@\",", _uuid];
    [content appendFormat:@"\"backlog\":%u,", backlog];
    [content appendString:@"\"states\":[],"];
    [content appendString:@"\"activities\":["];
    [content appendFormat:@"{\"hwid\":\"%@\",\"time\":%lu,\"interval\":%lu,\"vma\":[", hardwareId, (unsigned long)(time * 1000UL), (unsigned long)(interval * 1000UL)];
    BOOL first = YES;
    for (NSNumber *number in vmas) {
        if (first) {
            first = NO;
        } else {
            [content appendString:@","];
        }
        double vma = [number doubleValue];
        [content appendFormat:@"%0.3f", vma];
    }
    [content appendString:@"]}"];
	[content appendString:@"]}"];
	
    NSURL *url = [self urlForSite:site];
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
	[request setHTTPMethod:@"POST"];
    [request setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	NSMutableData *postBody = [NSMutableData data];
    NSLog(@"posting %@", content);
	[postBody appendData:[content dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPBody:[ZZGZIP compress:postBody]];
	_connectionData = [NSMutableData data];
	_connection = [NSURLConnection connectionWithRequest:request delegate:self];
	if (!_connection) {
		@throw [NSException exceptionWithName:@"CannotOpenConnection"
                                       reason:[NSString stringWithFormat:@"cannot open connection %@", [[request URL] absoluteString]]
                                     userInfo:nil];
	}
}

- (void)complete:(NSError *)error
{
    _connection = nil;
	_connectionData = nil;
    
	NSLog(@"upload complete %@", [error localizedDescription]);
    [_delegate upload:self complete:error];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	return nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)urlResponse
{
	NSHTTPURLResponse *response = (NSHTTPURLResponse *)urlResponse;
	int code = [response statusCode];
	if (code != 200) {
		[connection cancel];
		[self complete:[NSError errorWithDomain:@"ZZUpload" code:code userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"cannot post upload: unexpected http status code %d", code]}]];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[_connectionData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSError *error = nil;
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:_connectionData options:kNilOptions error:nil];
	BOOL success = [json[@"success"] boolValue];
    if (!success) {
        error = [NSError errorWithDomain:@"ZZUpload" code:0 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"upload did not return success result (%@)", json[@"success"]]}];
    }
	[self complete:error];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[self complete:error];
}

@end
