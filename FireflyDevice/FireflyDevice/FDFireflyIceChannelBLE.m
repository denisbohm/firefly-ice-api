//
//  FDFireflyIceChannelBLE.m
//  FireflyDevice
//
//  Created by Denis Bohm on 4/3/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#import <FireflyDevice/FDBinary.h>
#import <FireflyDevice/FDCobs.h>
#import <FireflyDevice/FDDetour.h>
#import <FireflyDevice/FDDetourSource.h>
#import <FireflyDevice/FDFireflyIceChannelBLE.h>
#import <FireflyDevice/FDFireflyDeviceLogger.h>
#import <FireflyDevice/FDWeak.h>

#define _log self.log

@implementation FDFireflyIceChannelBLERSSI

+ (FDFireflyIceChannelBLERSSI *)RSSI:(float)value date:(NSDate *)date
{
    FDFireflyIceChannelBLERSSI *RSSI = [[FDFireflyIceChannelBLERSSI alloc] init];
    RSSI.value = value;
    RSSI.date = date;
    return RSSI;
}

+ (FDFireflyIceChannelBLERSSI *)RSSI:(float)value
{
    return [FDFireflyIceChannelBLERSSI RSSI:value date:[NSDate date]];
}

@end

@implementation FDFireflyIceChannelBLEPeripheralObservable

+ (FDFireflyIceChannelBLEPeripheralObservable *)peripheralObservable
{
    FDFireflyIceChannelBLEPeripheralObservable *peripheralObservable = [[FDFireflyIceChannelBLEPeripheralObservable alloc] init];
    return peripheralObservable;
}

- (id)init
{
    if (self = [super init:@protocol(CBPeripheralDelegate)]) {
    }
    return self;
}

@end

@protocol FDFireflyIceChannelBLEPipe;

@protocol FDFireflyIceChannelBLEPipeDelegate

- (void)pipeReady:(id<FDFireflyIceChannelBLEPipe>)pipe;
- (void)pipe:(id<FDFireflyIceChannelBLEPipe>)pipe received:(NSData *)data;

- (void)detour:(FDDetour *)detour error:(NSError *)error;
- (void)writeValue:(NSData *)data forCharacteristic:(CBCharacteristic *)characteristic type:(CBCharacteristicWriteType)type;
- (void)setNotifyValue:(BOOL)enabled forCharacteristic:(CBCharacteristic *)characteristic;

@end

@protocol FDFireflyIceChannelBLEPipe <NSObject>

@property id<FDFireflyIceChannelBLEPipeDelegate> delegate;

- (void)shutdown;
- (void)send:(NSData *)data;

- (void)didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;
- (void)didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic value:(NSData *)value error:(NSError *)error;
- (void)didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;
- (void)didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error;

@end

@interface FDFireflyIceChannelBLEPipeCharacteristic: NSObject <FDFireflyIceChannelBLEPipe>

@property CBUUID *characteristicUUID;
@property CBUUID *characteristicNoResponseUUID;

@property CBCharacteristic *characteristic;
@property CBCharacteristic *characteristicNoResponse;

@property FDDetour *detour;
@property NSMutableArray *detourSources;

@property NSUInteger writePending;
@property NSUInteger writePendingLimit;

@end

@implementation FDFireflyIceChannelBLEPipeCharacteristic

@synthesize delegate;

- (id)init:(CBUUID *)characteristicUUID noResponse:(CBUUID *)characteristicNoResponseUUID
{
    if (self = [super init]) {
        _characteristicUUID = characteristicUUID;
        _characteristicNoResponseUUID = characteristicNoResponseUUID;
        
        _detour = [[FDDetour alloc] init];
        _detourSources = [NSMutableArray array];

        _writePendingLimit = 1;
    }
    return self;
}

- (void)shutdown
{
    [delegate setNotifyValue:NO forCharacteristic:_characteristic];
    
    _characteristic = nil;
    _characteristicNoResponse = nil;
    [_detour clear];
    [_detourSources removeAllObjects];
    _writePending = 0;
    _writePendingLimit = 1;
}

- (void)didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    _writePending = 0;
    [self checkWrite];
}

- (void)didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic value:(NSData *)value error:(NSError *)error
{
    [_detour detourEvent:value];
    if (_detour.state == FDDetourStateSuccess) {
        [delegate pipe:self received:_detour.data];
        [_detour clear];
    } else
    if (_detour.state == FDDetourStateError) {
        [delegate detour:_detour error:_detour.error];
        [_detour clear];
    }
}

- (void)checkWrite
{
    while ((_writePending < _writePendingLimit) && (_detourSources.count > 0)) {
        FDDetourSource *detourSource = [_detourSources objectAtIndex:0];
        NSData *subdata = [detourSource next];
        if (subdata != nil) {
            ++_writePending;
            if (_writePending < _writePendingLimit) {
                [delegate writeValue:subdata forCharacteristic:_characteristicNoResponse type:CBCharacteristicWriteWithoutResponse];
            } else {
                [delegate writeValue:subdata forCharacteristic:_characteristic type:CBCharacteristicWriteWithResponse];
            }
        } else {
            [_detourSources removeObjectAtIndex:0];
        }
    }
}

- (void)send:(NSData *)data
{
    [_detourSources addObject:[[FDDetourSource alloc] initWithSize:20 data:data]];
    [self checkWrite];
}

- (void)didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"didUpdateNotificationStateForCharacteristic %@ %@", characteristic, _characteristic);
    if (characteristic == _characteristic) {
        NSLog(@"pipeReady");
        [delegate pipeReady:self];
    }
}

- (void)didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    for (CBCharacteristic *characteristic in service.characteristics) {
        if ([_characteristicUUID isEqual:characteristic.UUID]) {
            NSLog(@"found characteristic");
            _characteristic = characteristic;
            
            [delegate setNotifyValue:YES forCharacteristic:_characteristic];
        } else
        if ([_characteristicNoResponseUUID isEqual:characteristic.UUID]) {
            NSLog(@"found characteristic no response");
            _characteristicNoResponse = characteristic;
        }
    }
    if ((_characteristic != nil) && (_characteristicNoResponse != nil)) {
        _writePendingLimit = 12;
    }
}

@end

@interface FDFireflyIceChannelBLEPipeL2CAP: NSObject <FDFireflyIceChannelBLEPipe, NSStreamDelegate>

@property CBL2CAPChannel *l2capChannel;
@property NSInputStream *inputStream;
@property NSOutputStream *outputStream;
@property NSMutableData *dataToSend;
@property NSMutableData *dataReceived;
@property NSUInteger streamOpenCount;

@end

@implementation FDFireflyIceChannelBLEPipeL2CAP

@synthesize delegate;

- (id)init
{
    if (self = [super init]) {
        _dataToSend = [NSMutableData data];
        _dataReceived = [NSMutableData data];
    }
    return self;
}

- (void)open:(CBL2CAPChannel *)l2capChannel
{
    _l2capChannel = l2capChannel;
    
    _inputStream = _l2capChannel.inputStream;
    _inputStream.delegate = self;
    [_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_inputStream open];
    
    _outputStream = _l2capChannel.outputStream;
    _outputStream.delegate = self;
    [_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_outputStream open];
}

- (void)shutdown
{
    _inputStream.delegate = nil;
    [_inputStream close];
    [_inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    _inputStream = nil;

    _outputStream.delegate = nil;
    [_outputStream close];
    [_outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    _outputStream = nil;
    
    _l2capChannel = nil;
    
    _streamOpenCount = 0;
}

- (void)checkSend
{
    while ((_dataToSend.length > 0) && _outputStream.hasSpaceAvailable) {
        NSInteger n = [_outputStream write:_dataToSend.bytes maxLength:_dataToSend.length];
        NSLog(@"L2CAP TX %ld %@", (long)n, [_dataToSend debugDescription]);
        if (n > 0) {
            [_dataToSend replaceBytesInRange:NSMakeRange(0, n) withBytes:nil length:0];
        }
    }
}

- (void)send:(NSData *)data
{
    NSLog(@"L2CAP send %@", [data debugDescription]);
    NSData *encodedData = [FDCobs encode:data];
    [_dataToSend appendData:encodedData];
    uint8_t delimiter = 0;
    [_dataToSend appendBytes:&delimiter length:1];
    [self checkSend];
}

- (void)received:(NSData *)data
{
    [_dataReceived appendData:data];
    
    for (NSUInteger i = 0; i < _dataReceived.length; ++i) {
        uint8_t *bytes = (uint8_t *)_dataReceived.bytes;
        uint8_t byte = bytes[i];
        if (byte == 0x00) {
            NSData *encoded = [_dataReceived subdataWithRange:NSMakeRange(0, i)];
            [_dataReceived replaceBytesInRange:NSMakeRange(0, i + 1) withBytes:0 length:0];
            i = 0;
            NSData *decoded = [FDCobs decode:encoded];
            NSLog(@"L2CAP process %@", [decoded debugDescription]);
            [delegate pipe:self received:decoded];
        }
    }
    
    NSLog(@"L2CAP received %@", [_dataReceived debugDescription]);
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventNone:
            NSLog(@"NSStreamEventNone");
            break;
        case NSStreamEventOpenCompleted:
            NSLog(@"NSStreamEventOpenCompleted");
            ++_streamOpenCount;
            if (_streamOpenCount == 2) {
                [delegate pipeReady:self];
            }
            break;
        case NSStreamEventHasBytesAvailable: {
            NSLog(@"NSStreamEventHasBytesAvailable");
            uint8_t buffer[512];
            NSInteger n = [_inputStream read:buffer maxLength:sizeof(buffer)];
            NSLog(@"L2CAP RX %ld", (long)n);
            if (n > 0) {
                [self received:[NSData dataWithBytes:buffer length:n]];
            }
        } break;
        case NSStreamEventHasSpaceAvailable:
            NSLog(@"NSStreamEventHasSpaceAvailable");
            [self checkSend];
            break;
        case NSStreamEventErrorOccurred:
            NSLog(@"NSStreamEventErrorOccurred");
            break;
        case NSStreamEventEndEncountered:
            NSLog(@"NSStreamEventEndEncountered");
            break;
    }
}

- (void)didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
}

- (void)didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic value:(NSData *)value error:(NSError *)error {
}

- (void)didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
}

- (void)didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
}

@end

@interface FDFireflyIceChannelBLE () <CBPeripheralDelegate, FDFireflyIceChannelBLEPipeDelegate>

@property FDFireflyIceChannelStatus status;
@property CBUUID *serviceUUID;
@property CBCentralManager *centralManager;
@property CBPeripheral *peripheral;

@property FDFireflyIceChannelBLEPipeCharacteristic *pipeCharacteristic;
@property FDFireflyIceChannelBLEPipeL2CAP *pipeL2cap;

@property id<FDFireflyIceChannelBLEPipe> pipe;

@end

@implementation FDFireflyIceChannelBLE

@synthesize log;

+ (NSString *)CBUUIDString:(CBUUID *)uuid;
{
    NSData *data = uuid.data;
    
    NSUInteger bytesToConvert = [data length];
    const unsigned char *uuidBytes = [data bytes];
    NSMutableString *outputString = [NSMutableString stringWithCapacity:16];
    
    for (NSUInteger currentByteIndex = 0; currentByteIndex < bytesToConvert; currentByteIndex++)
    {
        switch (currentByteIndex)
        {
            case 3:
            case 5:
            case 7:
            case 9:[outputString appendFormat:@"%02x-", uuidBytes[currentByteIndex]]; break;
            default:[outputString appendFormat:@"%02x", uuidBytes[currentByteIndex]];
        }
        
    }
    
    return outputString;
}

- (id)initWithCentralManager:(CBCentralManager *)centralManager withPeripheral:(CBPeripheral *)peripheral withServiceUUID:(CBUUID *)serviceUUID
{
    if (self = [super init]) {
        _serviceUUID = serviceUUID;

        _centralManager = centralManager;
        _peripheral = peripheral;
        _peripheralObservable = [FDFireflyIceChannelBLEPeripheralObservable peripheralObservable];
        [_peripheralObservable addObserver:self];
        _peripheral.delegate = _peripheralObservable;
        switch (_peripheral.state) {
            case CBPeripheralStateConnected:
                _status = FDFireflyIceChannelStatusOpen;
                break;
            case CBPeripheralStateConnecting:
                _status = FDFireflyIceChannelStatusOpening;
                break;
            case CBPeripheralStateDisconnecting:
                // add disconnecting status? -denis
                break;
            case CBPeripheralStateDisconnected:
                _status = FDFireflyIceChannelStatusClosed;
                break;
                
        }

        NSString *baseUUID = [FDFireflyIceChannelBLE CBUUIDString:serviceUUID];
        CBUUID *characteristicUUID = [CBUUID UUIDWithString:[baseUUID stringByReplacingCharactersInRange:NSMakeRange(4, 4) withString:@"0002"]];
        CBUUID *characteristicNoResponseUUID = [CBUUID UUIDWithString:[baseUUID stringByReplacingCharactersInRange:NSMakeRange(4, 4) withString:@"0003"]];
        _pipeCharacteristic = [[FDFireflyIceChannelBLEPipeCharacteristic alloc] init:characteristicUUID noResponse:characteristicNoResponseUUID];
        _pipeCharacteristic.delegate = self;

        _pipeL2cap = [[FDFireflyIceChannelBLEPipeL2CAP alloc] init];
        _pipeL2cap.delegate = self;
    }
    return self;
}

- (NSString *)name
{
    return @"BLE";
}

- (void)open
{
    [_centralManager connectPeripheral:_peripheral options:nil];
    self.status = FDFireflyIceChannelStatusConnecting;
    if ([_delegate respondsToSelector:@selector(fireflyIceChannel:status:)]) {
        [_delegate fireflyIceChannel:self status:self.status];
    }
}

- (void)pipe:(id<FDFireflyIceChannelBLEPipe>)pipe received:(NSData *)data
{
    if ([_delegate respondsToSelector:@selector(fireflyIceChannelPacket:data:)]) {
        [_delegate fireflyIceChannelPacket:self data:data];
    }
}

- (void)detour:(FDDetour *)detour error:(NSError *)error {
    if ([_delegate respondsToSelector:@selector(fireflyIceChannel:detour:error:)]) {
        [_delegate fireflyIceChannel:self detour:detour error:error];
    }
}

- (void)writeValue:(NSData *)data forCharacteristic:(CBCharacteristic *)characteristic type:(CBCharacteristicWriteType)type
{
    [_peripheral writeValue:data forCharacteristic:characteristic type:type];
}

- (void)setNotifyValue:(BOOL)enabled forCharacteristic:(CBCharacteristic *)characteristic
{
    if (
        ([_peripheral respondsToSelector:@selector(state)] && (_peripheral.state != CBPeripheralStateConnected)) ||
        (characteristic == nil)
    ) {
        return;
    }

    [_peripheral setNotifyValue:enabled forCharacteristic:characteristic];
}

- (void)shutdown
{
    [_pipeCharacteristic shutdown];
    [_pipeL2cap shutdown];
    _pipe = nil;
}

- (void)close
{
    [self shutdown];
    
    [_centralManager cancelPeripheralConnection:_peripheral];
    
    self.status = FDFireflyIceChannelStatusClosing;
    if ([_delegate respondsToSelector:@selector(fireflyIceChannel:status:)]) {
        [_delegate fireflyIceChannel:self status:self.status];
    }
}

- (void)didConnectPeripheral
{
    [_peripheral discoverServices:@[_serviceUUID]];
    self.status = FDFireflyIceChannelStatusOpening;
    if ([_delegate respondsToSelector:@selector(fireflyIceChannel:status:)]) {
        [_delegate fireflyIceChannel:self status:self.status];
    }
}

- (void)didDisconnectPeripheralError:(NSError *)error
{
    [self shutdown];
    
    self.status = FDFireflyIceChannelStatusClosed;
    if ([_delegate respondsToSelector:@selector(fireflyIceChannel:status:)]) {
        [_delegate fireflyIceChannel:self status:self.status];
    }
}

- (void)didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    [_pipeCharacteristic didWriteValueForCharacteristic:characteristic error:error];
    [_pipeL2cap didWriteValueForCharacteristic:characteristic error:error];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    __FDWeak FDFireflyIceChannelBLE *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf didWriteValueForCharacteristic:characteristic error:error];
    });
}

- (void)didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic value:(NSData *)value error:(NSError *)error
{
    [_pipeCharacteristic didUpdateValueForCharacteristic:characteristic value:value error:error];
    [_pipeL2cap didUpdateValueForCharacteristic:characteristic value:value error:error];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSData *data = characteristic.value;
    __FDWeak FDFireflyIceChannelBLE *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf didUpdateValueForCharacteristic:characteristic value:data error:error];
    });
}

- (void)fireflyIceChannelSend:(NSData *)data
{
    [_pipe send:data];
}

- (void)didDiscoverServices:(NSError *)error
{
    NSLog(@"didDiscoverServices");
    for (CBService *service in _peripheral.services) {
        if ([service.UUID isEqual:_serviceUUID]) {
            [_peripheral discoverCharacteristics:nil/*@[_characteristicUUID]*/ forService:service];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    __FDWeak FDFireflyIceChannelBLE *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf didDiscoverServices:error];
    });
}

- (void)didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    [_pipeCharacteristic didUpdateNotificationStateForCharacteristic:characteristic error:error];
    [_pipeL2cap didUpdateNotificationStateForCharacteristic:characteristic error:error];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    __FDWeak FDFireflyIceChannelBLE *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf didUpdateNotificationStateForCharacteristic:characteristic error:error];
    });
}

- (void)didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    [_pipeCharacteristic didDiscoverCharacteristicsForService:service error:error];
    [_pipeL2cap didDiscoverCharacteristicsForService:service error:error];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    __FDWeak FDFireflyIceChannelBLE *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf didDiscoverCharacteristicsForService:service error:error];
    });
}

- (void)didUpdateRSSI:(NSNumber *)RSSI error:(NSError *)error
{
    self.RSSI = [FDFireflyIceChannelBLERSSI RSSI:[RSSI floatValue]];
}

#if (__MAC_OS_X_VERSION_MIN_REQUIRED < 101300) && (__IPHONE_OS_VERSION_MIN_REQUIRED < 80000)

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error
{
    __FDWeak FDFireflyIceChannelBLE *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf didUpdateRSSI:peripheral.RSSI error:error];
    });
}

#endif

- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error
{
    __FDWeak FDFireflyIceChannelBLE *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf didUpdateRSSI:RSSI error:error];
    });
}

- (void)onOpen
{
    self.status = FDFireflyIceChannelStatusOpen;
    
    if ([_delegate respondsToSelector:@selector(fireflyIceChannel:status:)]) {
        [_delegate fireflyIceChannel:self status:self.status];
    }
}

- (void)usePipeCharacteristic
{
    _pipe = _pipeCharacteristic;
    [self onOpen];
}

- (void)pipeReady:(id<FDFireflyIceChannelBLEPipe>)pipe
{
    if (pipe == _pipeCharacteristic) {
        if (NSClassFromString(@"CBL2CAPChannel")) {
            NSLog(@"attempting to open L2CAP channel");
            [_peripheral openL2CAPChannel:0x25]; // 0x1001];
        } else {
            [self usePipeCharacteristic];
        }
    }
    if (pipe == _pipeL2cap) {
        [self usePipeL2cap];
    }
}

- (void)usePipeL2cap
{
    _pipe = _pipeL2cap;
    [self onOpen];
}

- (void)didOpenL2CAPChannel:(CBL2CAPChannel *)channel error:(NSError *)error
{
    if (channel == nil) {
        NSLog(@"openL2CAPChannel error: %@", error.description);
        [self usePipeCharacteristic];
        return;
    }
    
    [_pipeL2cap open:channel];
}

- (void)peripheral:(CBPeripheral *)peripheral didOpenL2CAPChannel:(CBL2CAPChannel *)channel error:(NSError *)error
{
    __FDWeak FDFireflyIceChannelBLE *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf didOpenL2CAPChannel:channel error:error];
    });
}

@end
