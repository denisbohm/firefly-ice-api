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

#import <ARMSerialWireDebug/FDSerialEngine.h>
#import <ARMSerialWireDebug/FDSerialWireDebug.h>
#import <ARMSerialWireDebug/FDUSBDevice.h>
#import <ARMSerialWireDebug/FDUSBMonitor.h>

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

@interface FDAppDelegate () <CBCentralManagerDelegate, FDUSBMonitorDelegate, FDUSBHIDMonitorDelegate, FDUSBHIDDeviceDelegate, FDFireflyDeviceDelegate, NSTableViewDataSource>

@property (assign) IBOutlet NSTableView *bluetoothTableView;
@property CBCentralManager *centralManager;
@property NSMutableArray *fireflyDevices;

@property (assign) IBOutlet NSTableView *usbTableView;
@property FDUSBHIDMonitor *usbMonitor;
@property FDUSBTableViewDataSource *usbTableViewDataSource;

@property (assign) IBOutlet NSTableView *swdTableView;
@property FDUSBMonitor *swdMonitor;
@property FDUSBTableViewDataSource *swdTableViewDataSource;

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
    
    _swdMonitor = [[FDUSBMonitor alloc] init];
    _swdMonitor.vendor = 0x15ba;
    _swdMonitor.product = 0x002a;
    _swdMonitor.delegate = self;
    _swdTableViewDataSource = [[FDUSBTableViewDataSource alloc] init];
    _swdTableView.dataSource = _swdTableViewDataSource;
    
    [_usbMonitor start];
    [_swdMonitor start];
}

- (void)usbMonitor:(FDUSBMonitor *)usbMonitor usbDeviceAdded:(FDUSBDevice *)device
{
    [_swdTableViewDataSource.devices addObject:device];
    [_swdTableView reloadData];
}

- (void)usbMonitor:(FDUSBMonitor *)usbMonitor usbDeviceRemoved:(FDUSBDevice *)device
{
    [_swdTableViewDataSource.devices removeObject:device];
    [_swdTableView reloadData];
}

- (FDUSBDevice *)getSelectedSwdDevice
{
    NSInteger row = _swdTableView.selectedRow;
    if (row < 0) {
        return nil;
    }
    return [_swdTableViewDataSource.devices objectAtIndex:row];
}

#define EnergyMicro_DebugPort_IdentifcationCode 0x2ba01477

- (IBAction)swdReset:(id)sender
{
    FDUSBDevice *usbDevice = [self getSelectedSwdDevice];
    [usbDevice open];
    FDSerialEngine *serialEngine = [[FDSerialEngine alloc] init];
    serialEngine.usbDevice = usbDevice;
    FDSerialWireDebug *serialWireDebug = [[FDSerialWireDebug alloc] init];
    serialWireDebug.serialEngine = serialEngine;
    [serialWireDebug initialize];
    [serialWireDebug setGpioIndicator:true];
    [serialWireDebug setGpioReset:true];
    [serialEngine write];
    [NSThread sleepForTimeInterval:0.001];
    [serialWireDebug setGpioReset:false];
    [serialEngine write];
    [NSThread sleepForTimeInterval:0.100];
    
    [serialWireDebug resetDebugAccessPort];
    uint32_t debugPortIDCode = [serialWireDebug readDebugPortIDCode];
    NSLog(@"DPID = %08x", debugPortIDCode);
    if (debugPortIDCode != EnergyMicro_DebugPort_IdentifcationCode) {
        NSLog(@"unexpected debug port identification code");
    }
    [serialWireDebug initializeDebugAccessPort];
    NSLog(@"read CPU ID");
    uint32_t cpuID = [serialWireDebug readCPUID];
    NSLog(@"CPUID = %08x", cpuID);
    if ((cpuID & 0xfffffff0) == 0x412FC230) {
        uint32_t n = cpuID & 0x0000000f;
        NSLog(@"ARM Cortex-M3 r2p%d", n);
    }
    
    [serialWireDebug halt];
    
    NSLog(@"write memory");
    uint32_t address = 0x20000000;
    [serialWireDebug writeMemory:address value:0x01234567];
    [serialWireDebug checkDebugPortStatus];
    [serialWireDebug writeMemory:address+4 value:0x76543210];
    NSLog(@"read memory");
    uint32_t m0 = [serialWireDebug readMemory:address];
    uint32_t m1 = [serialWireDebug readMemory:address+4];
    
    NSLog(@"write register");
    [serialWireDebug writeRegister:0 value:0x01234567];
    [serialWireDebug writeRegister:1 value:0x76543210];
    NSLog(@"read register");
    uint32_t r0 = [serialWireDebug readRegister:0];
    uint32_t r1 = [serialWireDebug readRegister:1];
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
