//
//  FDAppDelegate.m
//  Sync
//
//  Created by Denis Bohm on 4/3/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDAppDelegate.h"
#import "FDFireflyDevice.h"
#import "FDUSBHIDMonitor.h"

#if TARGET_OS_IPHONE
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif

@interface FDUSBTableViewDataSource : NSObject  <NSTableViewDataSource>

@property NSMutableArray *devices;

@end

@implementation FDUSBTableViewDataSource

- (id)init
{
    if (self = [super init]) {
        _devices = [NSMutableArray array];
    }
    return self;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return _devices.count;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    return [[_devices objectAtIndex:rowIndex] description];
}

@end

@interface FDAppDelegate () <CBCentralManagerDelegate, FDUSBHIDMonitorDelegate, FDUSBHIDDeviceDelegate, FDFireflyDeviceDelegate, NSTableViewDataSource>

@property (assign) IBOutlet NSTableView *bluetoothTableView;
@property CBCentralManager *centralManager;
@property NSMutableArray *fireflyDevices;

@property (assign) IBOutlet NSTableView *usbTableView;
@property FDUSBHIDMonitor *usbMonitor;
@property FDUSBTableViewDataSource *usbTableViewDataSource;

@property (assign) IBOutlet NSSlider *axSlider;
@property (assign) IBOutlet NSSlider *aySlider;
@property (assign) IBOutlet NSSlider *azSlider;

@property (assign) IBOutlet NSSlider *mxSlider;
@property (assign) IBOutlet NSSlider *mySlider;
@property (assign) IBOutlet NSSlider *mzSlider;

@end

@implementation FDAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    _fireflyDevices = [NSMutableArray array];
    _bluetoothTableView.dataSource = self;
    
    _usbMonitor = [[FDUSBHIDMonitor alloc] init];
    _usbMonitor.vendor = 0x2544;
    _usbMonitor.product = 0x0001;
    _usbMonitor.delegate = self;
    _usbTableViewDataSource = [[FDUSBTableViewDataSource alloc] init];
    _usbTableView.dataSource = _usbTableViewDataSource;
    
    [_usbMonitor start];
}

- (void)usbHidMonitor:(FDUSBHIDMonitor *)monitor deviceAdded:(FDUSBHIDDevice *)device
{
    device.delegate = self;
    
    [_usbTableViewDataSource.devices addObject:device];
    [_usbTableView reloadData];
}

- (void)usbHidMonitor:(FDUSBHIDMonitor *)monitor deviceRemoved:(FDUSBHIDDevice *)device
{
    device.delegate = nil;
    
    [_usbTableViewDataSource.devices removeObject:device];
    [_usbTableView reloadData];
}

#define FD_SYNC_START 1
#define FD_SYNC_DATA 2
#define FD_SYNC_ACK 3

- (void)sync:(FDUSBHIDDevice *)device data:(NSData *)data
{
    NSURL *url = [NSURL URLWithString:@"http://localhost:5000/sync"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request addValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%ld", (unsigned long)data.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:data];
    
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    uint8_t sequence_number = 0x00;
    uint16_t length = responseData.length;
    uint8_t bytes[] = {sequence_number, length, length >> 8};
    NSMutableData *ackData = [NSMutableData dataWithBytes:bytes length:sizeof(bytes)];
    [ackData appendData:responseData];
    [device setReport:ackData];
}

- (void)sensing:(NSData *)data
{
    NSLog(@"sensing data received %@", data);
}

- (void)usbHidDevice:(FDUSBHIDDevice *)device inputReport:(NSData *)data
{
    NSLog(@"inputReport %@", data);
    
    if (data.length < 1) {
        return;
    }
    
    uint8_t code = ((uint8_t *)data.bytes)[0];
    switch (code) {
        case FD_SYNC_DATA:
            [self sync:device data:data];
            break;
        case 0xff:
            [self sensing:data];
            break;
    }
}

- (FDUSBHIDDevice *)getSelectedUsbDevice
{
    NSInteger row = _usbTableView.selectedRow;
    if (row < 0) {
        return nil;
    }
    return [_usbTableViewDataSource.devices objectAtIndex:row];
}

- (IBAction)usbOpen:(id)sender
{
    FDUSBHIDDevice *device = [self getSelectedUsbDevice];
    [device open];
}

- (IBAction)usbClose:(id)sender
{
    FDUSBHIDDevice *device = [self getSelectedUsbDevice];
    [device close];
}

- (IBAction)usbWrite:(id)sender
{
    uint8_t sequence_number = 0x00;
    uint16_t length = 1;
    uint8_t bytes[] = {sequence_number, length, length >> 8, FD_SYNC_START};
    NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];

    FDUSBHIDDevice *device = [self getSelectedUsbDevice];
    [device setReport:data];
}

- (void)fireflyDevice:(FDFireflyDevice *)fireflyDevice
                   ax:(float)ax ay:(float)ay az:(float)az
                   mx:(float)mx my:(float)my mz:(float)mz
{
    _axSlider.floatValue = ax;
    _aySlider.floatValue = ay;
    _azSlider.floatValue = az;

    _mxSlider.floatValue = mx;
    _mySlider.floatValue = my;
    _mzSlider.floatValue = mz;
}

- (FDFireflyDevice *)getSelectedFireflyDevice
{
    NSInteger row = _bluetoothTableView.selectedRow;
    if (row < 0) {
        return nil;
    }
    return [_fireflyDevices objectAtIndex:row];
}

- (IBAction)bluetoothConnect:(id)sender
{
    FDFireflyDevice *fireflyDevice = [self getSelectedFireflyDevice];
    fireflyDevice.delegate = self;
    [_centralManager connectPeripheral:fireflyDevice.peripheral options:nil];
}

- (IBAction)bluetoothDisconnect:(id)sender
{
    FDFireflyDevice *fireflyDevice = [self getSelectedFireflyDevice];
    fireflyDevice.delegate = nil;
    [_centralManager cancelPeripheralConnection:fireflyDevice.peripheral];
}

- (IBAction)bluetoothWrite:(id)sender
{
    FDFireflyDevice *fireflyDevice = [self getSelectedFireflyDevice];
    [fireflyDevice write];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return _fireflyDevices.count;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    return [[_fireflyDevices objectAtIndex:rowIndex] description];
}

- (void)centralManagerPoweredOn
{
    [_centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"310a0001-1b95-5091-b0bd-b7a681846399"]] options:nil];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBCentralManagerStateUnknown:
        case CBCentralManagerStateResetting:
        case CBCentralManagerStateUnsupported:
        case CBCentralManagerStateUnauthorized:
            break;
        case CBCentralManagerStatePoweredOff:
            break;
        case CBCentralManagerStatePoweredOn:
            [self centralManagerPoweredOn];
            break;
    }
}

- (FDFireflyDevice *)getFireflyDeviceByPeripheral:(CBPeripheral *)peripheral
{
    for (FDFireflyDevice *fireflyDevice in _fireflyDevices) {
        if (fireflyDevice.peripheral == peripheral) {
            return fireflyDevice;
        }
    }
    return nil;
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    FDFireflyDevice *fireflyDevice = [self getFireflyDeviceByPeripheral:peripheral];
    if (fireflyDevice != nil) {
        return;
    }

    NSLog(@"didDiscoverPeripheral %@", peripheral);
    fireflyDevice = [[FDFireflyDevice alloc] initWithPeripheral:peripheral];
    [_fireflyDevices addObject:fireflyDevice];
    
    [_bluetoothTableView reloadData];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"didConnectPeripheral %@", peripheral.name);
    FDFireflyDevice *fireflyDevice = [self getFireflyDeviceByPeripheral:peripheral];
    [fireflyDevice didConnectPeripheral];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"didDisconnectPeripheral %@ : %@", peripheral.name, error);
    FDFireflyDevice *fireflyDevice = [self getFireflyDeviceByPeripheral:peripheral];
    [fireflyDevice didDisconnectPeripheralError:error];
}


@end
