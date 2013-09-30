//
//  ZZActivityUploader.m
//  Activity
//
//  Created by Denis Bohm on 11/8/11.
//

#import "ZZActivityUploader.h"
#import "ZZBinaryData.h"
#import "ZZGZIP.h"
#import "ZZIEEE754Binary16Converter.h"

#include <sqlite3.h>

@interface ZZActivityUploader () {

	sqlite3* _database;
	NSCondition* _lock;
	unsigned int _uploadMin;
	unsigned int _uploadMax;
	NSURLConnection* _connection;
	NSMutableData* _connectionData;
    NSTimer *_postTimer;

}

@property(strong, readonly) NSOperationQueue *operationQueue;

- (void)check;

@end

@interface ZZActivityUploaderCheckOperation : NSOperation {
    
}

@property(weak) ZZActivityUploader* activityUploader;

@end

@implementation ZZActivityUploaderCheckOperation

@synthesize activityUploader = _activityUploader;

- (void)main
{
    [_activityUploader check];
}

@end

#define LOCK @try { [_lock lock];
#define UNLOCK } @finally { [_lock signal]; [_lock unlock]; }

@implementation ZZActivityUploader

@synthesize filename = _filename;
@synthesize url = _url;
@synthesize hardwareId = _hardwareId;
@synthesize activityInterval = _activityInterval;
@synthesize username = _username;
@synthesize password = _password;
@synthesize platform = _platform;
@synthesize revision = _revision;
@synthesize uuid = _uuid;
@synthesize postInterval = _postInterval;
@synthesize operationQueue = _operationQueue;

- (id) init {
    if (self = [super init]) {
		_lock = [[NSCondition alloc] init];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        _filename = [documentsDirectory stringByAppendingPathComponent:@"ActivityUploader.sqlite3"];
        _username = @"firefly";
        _password = @"design";
        UIDevice *device = [UIDevice currentDevice];
        _platform = [NSString stringWithFormat:@"%@ %@", [device systemName], [device systemVersion]];
        _revision = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] intValue];
        _postInterval = 60;
        _operationQueue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (void) check:(int) result withCode:(int) code {
	if (result != code) {
		if (result == SQLITE_CORRUPT) {
			NSLog(@"Upload database is corrupt.  Attempting to recreate...");
			[self close];
			[[NSFileManager defaultManager] removeItemAtPath:_filename error:nil];
			[self open];
		} else {
			const char* error_message = sqlite3_errmsg(_database);
			@throw [NSException
					exceptionWithName:@"Sqlite3Error" 
					reason:[NSString stringWithFormat:@"sqlite3 error (expected %d) %d: %s", code, result, error_message]
					userInfo: nil];
		}
	}
}

- (void) check:(int) result {
	[self check:result withCode:SQLITE_OK];
}

- (NSArray*) exec:(NSString*) sql, ... {
	NSMutableArray* rows = [NSMutableArray array];
	sqlite3_stmt* statement = nil;
	@try {
		const char* csql = [sql UTF8String];
		[self check:sqlite3_prepare_v2(_database, csql, -1, &statement, nil)];
		
		va_list args;
		va_start(args, sql);
		int index = 1;
		NSObject* value;
		while ((value = va_arg(args, NSString*)) != nil) {
            if ([value isKindOfClass:[NSString class]]) {
                const char* cvalue = [((NSString *)value) UTF8String];
                [self check:sqlite3_bind_text(statement, index++, cvalue, -1, SQLITE_TRANSIENT)];
            } else
            if ([value isKindOfClass:[NSNumber class]]) {
                int ivalue = [((NSNumber *)value) intValue];
                [self check:sqlite3_bind_int(statement, index++, ivalue)];
            } else
            if ([value isKindOfClass:[NSData class]]) {
                NSData *data = (NSData *)value;
                int length = [data length];
                const void *bytes = [data bytes];
                [self check:sqlite3_bind_blob(statement, index++, bytes, length, SQLITE_TRANSIENT)];
            } else {
                NSString *className = [[value class] description];
                @throw [NSException
                        exceptionWithName:@"Sqlite3Error" 
                        reason:[NSString stringWithFormat:@"sqlite3 error: unknown arg class: %@", className]
                        userInfo: nil];
            }
		}
		va_end(args);
		
		int column_count = sqlite3_column_count(statement);
		NSMutableArray* column_names = [NSMutableArray array];
		for (int i = 0; i < column_count; ++i) {
			const char* cname = sqlite3_column_name(statement, i);
			[column_names addObject:[NSString stringWithFormat:@"%s", cname]];
		}
		
		int result;
		while ((result = sqlite3_step(statement)) == SQLITE_ROW) {
			NSMutableDictionary* row = [NSMutableDictionary dictionaryWithCapacity:column_count];
			for (int i = 0; i < column_count; ++i) {
				NSString* name = [column_names objectAtIndex:i];
                NSObject* value = nil;
                int type = sqlite3_column_type(statement, i);
                switch (type) {
                    case SQLITE_TEXT: {
                        const unsigned char* cvalue = sqlite3_column_text(statement, i);
                        value = [NSString stringWithFormat:@"%s", cvalue];
                    } break;
                    case SQLITE_INTEGER: {
                        int n = sqlite3_column_int(statement, i);
                        value = [NSNumber numberWithInt:n];
                    } break;
                    case SQLITE_BLOB: {
                        int length = sqlite3_column_bytes(statement, i);
                        const void *bytes = sqlite3_column_blob(statement, i);
                        value = [NSData dataWithBytes:bytes length:length];
                    } break;
                }
				if (value) {
                    [row setObject:value forKey:name];
                }
			}
			[rows addObject:row];
		}
		
		[self check:result withCode:SQLITE_DONE];
	} @finally {
		sqlite3_finalize(statement);
	}
	return rows;
}

- (void) open {
	NSString* directory = [_filename stringByDeletingLastPathComponent];
    NSError* error = nil;
	if (![[NSFileManager defaultManager] createDirectoryAtPath: directory withIntermediateDirectories:YES attributes: nil error:&error]) {
        NSLog(@"cannot create directory for database: %@ %@", error, [error userInfo]);
    }
	const char* name = [_filename UTF8String];
	[self check:sqlite3_open(name, &_database)];	
	[self exec:@"CREATE TABLE IF NOT EXISTS items (sequence INTEGER PRIMARY KEY, time INTEGER, data BLOB)", nil];
}

- (void) close {
	sqlite3_close(_database);
	_database = nil;
}

- (void) clearConnection {
	LOCK
	_connectionData = nil;
    _connection = nil;
	UNLOCK
}

- (void) connection: (NSURLConnection *) theConnection didFailWithError: (NSError*) error {
	[self clearConnection];
	NSLog(@"Cannot post upload: %@", [error localizedDescription]);
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	NSLog(@"Unexpected authentication challenge.");
}

- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	NSLog(@"Unexpected cancel authentication challenge.");
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
	return nil;
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
	return request;
}

- (void)connection:(NSURLConnection *)theConnection didReceiveResponse:(NSURLResponse *)theResponse {
    //	[ZZLogger info:@"didReceiveResponse"];
	
	NSHTTPURLResponse* response = (NSHTTPURLResponse*) theResponse;
	int code = [response statusCode];
	if (code != 200) {
		[theConnection cancel];
		[self clearConnection];
		NSLog(@"Cannot post upload: unexpected http status code %d", code);
	}
}

- (void) connection: (NSURLConnection*) connection didReceiveData: (NSData*) data {
    //	[ZZLogger info:@"didReceiveData"];
	[_connectionData appendData:data];
}

- (void) connectionDidFinishLoading: (NSURLConnection *) theConnection {
    //	NSString* contentString = [[NSString alloc] initWithBytes:[connectionData_ bytes] length:[connectionData_ length] encoding:NSUTF8StringEncoding];
    //	[ZZLogger info:[NSString stringWithFormat:@"connectionDidFinishLoading: %@", contentString]];
	
	[self clearConnection];
	
	[self exec:[NSString stringWithFormat:@"DELETE FROM items WHERE sequence BETWEEN %d AND %d", _uploadMin, _uploadMax], nil];
}

- (int) backlogWithout:(int)n {
    NSArray* rows = [self exec:@"SELECT COUNT(*) AS count FROM items", nil];
	if ([rows count] > 0) {
        NSDictionary* row = [rows objectAtIndex:0];
        int count = [[row valueForKey:@"count"] intValue];
        int pages = ceil((count - n)/ 200.0);
        return pages;
    }
    return 0;
}

- (void) postUpload: (NSArray*) rows {
	NSDictionary* firstRow = [rows objectAtIndex:0];
	_uploadMin = [[firstRow valueForKey:@"sequence"] intValue];
	NSDictionary* lastRow = [rows lastObject];
	_uploadMax = [[lastRow valueForKey:@"sequence"] intValue];
	
	NSMutableString* content = [NSMutableString stringWithString:@"{"];
    [content appendFormat:@"\"username\":\"%@\",", _username];
    [content appendFormat:@"\"password\":\"%@\",", _password];
    [content appendFormat:@"\"platform\":\"%@\",", _platform];
    [content appendFormat:@"\"revision\":%d,", _revision];
    [content appendFormat:@"\"uuid\":\"%@\",", _uuid];
    [content appendFormat:@"\"backlog\":%d,", [self backlogWithout:_uploadMax - _uploadMin + 1]];
    [content appendString:@"\"states\":[],"];
    [content appendString:@"\"activities\":["];
    BOOL nth = NO;
	for (NSDictionary* row in rows) {
        if (nth) {
            [content appendString:@","];
        } else {
            nth = YES;
        }
		NSNumber* time = [row valueForKey:@"time"];
        [content appendFormat:@"{\"hwid\":\"%@\",\"time\":%d000,\"interval\":%d000,\"vma\":[", _hardwareId, [time intValue], _activityInterval];
        NSData *data = [row valueForKey:@"data"];
        ZZBinaryData *binary = [[ZZBinaryData alloc] initWithData:data];
        while (![binary isEmpty]) {
            if ([binary index] > 0) {
                [content appendString:@","];
            }
            double value = [binary readFloat16];
            [content appendFormat:@"%0.3f", value];
        }
        [content appendString:@"]}"];
	}
	[content appendString:@"]}"];
	
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:_url];
	[request setHTTPMethod:@"POST"];
    [request setValue: @"gzip" forHTTPHeaderField: @"Content-Encoding"];
	[request setValue: @"application/json" forHTTPHeaderField: @"Content-Type"];
	NSMutableData *postBody = [NSMutableData data];
	[postBody appendData:[content dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPBody: [ZZGZIP compress:postBody]];
	_connection = [NSURLConnection connectionWithRequest: request delegate: self];
	if (!_connection) {
		NSLog(@"cannot open connection %@", [[request URL] absoluteString]);
		return;
	}
	_connectionData = [NSMutableData data];
}

- (void)check
{
	LOCK
	if (_connection != nil) {
        return;
    }
    NSArray* rows = [self exec:@"SELECT sequence, time, data FROM items ORDER BY sequence ASC LIMIT 100", nil];
    if ([rows count] > 0) {
        [self postUpload:rows];
    }
	UNLOCK
}

- (void)checkPost:(NSTimer*)timer
{
    ZZActivityUploaderCheckOperation *operation = [[ZZActivityUploaderCheckOperation alloc] init];
    [operation setActivityUploader:self];
    [_operationQueue addOperation:operation];
}

- (void)start
{
    _postTimer = [NSTimer scheduledTimerWithTimeInterval:_postInterval target:self selector:@selector(check) userInfo:nil repeats:YES];
}

- (void)stop
{
    [_postTimer invalidate];
    _postTimer = nil;
}

- (void)fire
{
    [_postTimer fire];    
}

- (void)addActivityValue:(ZZActivityValue)value time:(NSTimeInterval)time
{
    sqlite3_int64 sequence;
	LOCK
    int utime = (int) [[NSDate dateWithTimeIntervalSinceReferenceDate:time] timeIntervalSince1970];
    ZZBinaryData *binary = [[ZZBinaryData alloc] init];
    [binary writeFloat16:(float)value];
    NSData *data = [binary data];
	[self exec:@"INSERT INTO items (time, data) VALUES (?, ?)", [NSNumber numberWithInt:utime], data, nil];
    sequence = sqlite3_last_insert_rowid(_database);
	UNLOCK
}

- (void)activityValue:(ZZActivityValue)value time:(NSTimeInterval)time
{
    ZZActivityUploader __weak *this = self;
    [_operationQueue addOperationWithBlock:^{
        [this addActivityValue:value time:time];
    }];
}

@end
