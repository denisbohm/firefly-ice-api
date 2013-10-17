//
//  FDAppDelegate.m
//  Sync
//
//  Created by Denis Bohm on 4/3/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDAppDelegate.h"

#import <ZamzeeDevice/ZZSyncTask.h>

#import <FireflyDevice/FDBinary.h>
#import <FireflyDevice/FDFireflyIce.h>
#import <FireflyDevice/FDFireflyIceChannelBLE.h>
#import <FireflyDevice/FDFireflyIceChannelUSB.h>
#import <FireflyDevice/FDFireflyIceCoder.h>
#import <FireflyDevice/FDFirmwareUpdateTask.h>
#import <FireflyDevice/FDHelloTask.h>
#import <FireflyDevice/FDIntelHex.h>
#import <FireflyDevice/FDUSBHIDMonitor.h>

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

@interface FDActivityPlotDataSource : NSObject <CPTPlotDataSource>

@property NSMutableArray *data;
@property NSNumber *xField;
@property NSNumber *yField;

@end

@implementation FDActivityPlotDataSource

- (id)init
{
    if (self = [super init]) {
        _data = [NSMutableArray array];
        _xField = [NSNumber numberWithInteger:CPTScatterPlotFieldX];
        _yField = [NSNumber numberWithInteger:CPTScatterPlotFieldY];
    }
    return self;
}

- (void)removeAll
{
    [_data removeAllObjects];
}

- (void)addActivityTime:(uint32)time value:(double)value
{
    [_data addObject:@{_xField:[NSNumber numberWithInteger:time], _yField: [NSNumber numberWithDouble:value]}];
}

- (NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    return _data.count;
}

- (NSNumber *)fieldFor:(NSUInteger)fieldEnum
{
    return (fieldEnum == CPTScatterPlotFieldX) ? _xField : _yField;
}

- (NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    return [[_data objectAtIndex:index] objectForKey:[self fieldFor:fieldEnum]];
}

@end

@interface FDAppDelegate () <CBCentralManagerDelegate, FDUSBHIDMonitorDelegate, NSTableViewDataSource, FDFireflyIceObserver, FDHelloTaskDelegate, ZZSyncTaskDelegate>

@property NSMutableArray *devices;

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

@property (assign) IBOutlet CPTGraphHostingView *graphHostingView;
@property CPTXYGraph *activityGraph;
@property CPTScatterPlot *activityPlot;
@property FDActivityPlotDataSource *activityPlotDataSource;

@property ZZSyncTask *syncTask;

@end

@implementation FDAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    _devices = [NSMutableArray array];
    
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    _fireflyDevices = [NSMutableArray array];
    _bluetoothTableView.dataSource = self;
    
    _usbMonitor = [[FDUSBHIDMonitor alloc] init];
//    _usbMonitor.vendor = 0x2544;
//    _usbMonitor.product = 0x0001;
    _usbMonitor.vendor = 0x2333;
    _usbMonitor.product = 0x0002;
    _usbMonitor.delegate = self;
    _usbTableViewDataSource = [[FDUSBTableViewDataSource alloc] init];
    _usbTableView.dataSource = _usbTableViewDataSource;
    
    [self setupGraph];
    
    [_usbMonitor start];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel status:(FDFireflyIceChannelStatus)status
{
    switch (status) {
        case FDFireflyIceChannelStatusOpening:
            break;
        case FDFireflyIceChannelStatusOpen:
            [fireflyIce.executor execute:[FDHelloTask helloTask:fireflyIce channel:channel delegate:self]];
            break;
        case FDFireflyIceChannelStatusClosed:
            break;
    }
}

- (void)syncTaskActive:(ZZSyncTask *)syncTask
{
    NSLog(@"delegate syncTask active");    
}

- (void)syncTask:(ZZSyncTask *)syncTask error:(NSError *)error
{
    NSLog(@"delegate syncTask error %@", error);
}

- (void)syncTask:(ZZSyncTask *)syncTask progress:(float)progress
{
    NSLog(@"delegate syncTask progress %f", progress);
}

- (void)syncTaskComplete:(ZZSyncTask *)syncTask
{
    NSLog(@"delegate syncTask complete");
}

- (void)syncTaskInactive:(ZZSyncTask *)syncTask
{
    NSLog(@"delegate syncTask inactive");
}

- (void)helloTaskComplete:(FDHelloTask *)helloTask
{
    FDFireflyIce *fireflyIce = helloTask.fireflyIce;
    id<FDFireflyIceChannel> channel = helloTask.channel;
    _syncTask = [ZZSyncTask syncTask:fireflyIce channel:channel];
    _syncTask.delegate = self;
    [fireflyIce.executor execute:_syncTask];
//    [fireflyIce.executor execute:[FDFirmwareUpdateTask firmwareUpdateTask:fireflyIce channel:channel]];
}

- (void)fireflyIceSensing:(id<FDFireflyIceChannel>)channel ax:(float)ax ay:(float)ay az:(float)az mx:(float)mx my:(float)my mz:(float)mz
{
    /*
     _axSlider.floatValue = ax;
     _aySlider.floatValue = ay;
     _azSlider.floatValue = az;
     
     _mxSlider.floatValue = mx;
     _mySlider.floatValue = my;
     _mzSlider.floatValue = mz;
     */
}

- (void)setupGraph
{
    // Create graph and apply a dark theme
    _activityGraph = [(CPTXYGraph *)[CPTXYGraph alloc] initWithFrame:NSRectToCGRect(_graphHostingView.bounds)];
    _graphHostingView.hostedGraph = _activityGraph;
    
    // Graph title
    _activityGraph.title = @"Activity";
    CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
    textStyle.color = [CPTColor grayColor];
    textStyle.fontName = @"Helvetica-Bold";
    textStyle.fontSize = 14.0;
    _activityGraph.titleTextStyle = textStyle;
    _activityGraph.titleDisplacement = CGPointMake(0.0, 10.0);
    _activityGraph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
    
    // Graph padding
    _activityGraph.paddingLeft = 20.0;
    _activityGraph.paddingTop = 20.0;
    _activityGraph.paddingRight = 20.0;
    _activityGraph.paddingBottom = 20.0;
    
    _activityPlotDataSource = [[FDActivityPlotDataSource alloc] init];
    
    _activityPlot = [[CPTScatterPlot alloc] init];
    _activityPlot.identifier = @"Activity";
    CPTMutableLineStyle *lineStyle = [_activityPlot.dataLineStyle mutableCopy];
    lineStyle.lineWidth = 3.0;
    lineStyle.lineColor = [CPTColor redColor];
    _activityPlot.dataLineStyle = lineStyle;
    _activityPlot.dataSource = _activityPlotDataSource;
    [_activityGraph addPlot:_activityPlot];
    
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)_activityGraph.defaultPlotSpace;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInteger(0) length:CPTDecimalFromInteger(10)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInteger(0) length:CPTDecimalFromInteger(10)];
}

- (IBAction)refreshPlot:(id)sender
{
    NSDictionary *query = @{@"query": @{@"type": @"vmas", @"end": @"$max", @"duration": @"1d"}};
    NSError *error = nil;
    NSData* data = [NSJSONSerialization dataWithJSONObject:query options:0 error:&error];
    NSURL *url = [NSURL URLWithString:@"http://localhost:5000/query"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%ld", data.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:data];
    
    NSURLResponse *response = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    id responseJson = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
    NSDictionary *result = responseJson[@"result"];
    NSArray *vmasArray = result[@"vmas"];
    [_activityPlotDataSource removeAll];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss z"];
    uint32_t firstTime = 0;
    for (NSDictionary *vmas in vmasArray) {
        NSString *s = vmas[@"time"];
        s = [s stringByReplacingOccurrencesOfString:@"UTC" withString:@"+0000"];
        NSDate *d = [formatter dateFromString:s];
        NSTimeInterval t = [d timeIntervalSince1970];
        uint32_t time = (uint32_t)t;
        if (firstTime == 0) {
            firstTime = time;
        }
        uint16_t interval = [vmas[@"interval"] integerValue];
        NSArray *values = vmas[@"values"];
        for (NSNumber *value in values) {
            double v = [value doubleValue] * 1000;
            NSLog(@"point %u, %0.1f", time, v);
            [_activityPlotDataSource addActivityTime:firstTime - time value:v];
            time += interval;
        }
    }
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)_activityGraph.defaultPlotSpace;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInteger(0) length:CPTDecimalFromInteger(200)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInteger(0) length:CPTDecimalFromInteger(10)];
    [_activityGraph reloadData];
}

- (void)usbHidMonitor:(FDUSBHIDMonitor *)monitor deviceAdded:(FDUSBHIDDevice *)usbHidDevice
{
    FDFireflyIce *fireflyIce = [[FDFireflyIce alloc] init];
    [fireflyIce.observable addObserver:self];
    [_devices addObject:fireflyIce];
    FDFireflyIceChannelUSB *channel = [[FDFireflyIceChannelUSB alloc] initWithDevice:usbHidDevice];
    [fireflyIce addChannel:channel type:@"USB"];
    [_usbTableViewDataSource.devices addObject:channel];
    [_usbTableView reloadData];
}

- (FDFireflyIceChannelUSB *)channelForUSBDevice:(FDUSBHIDDevice *)device
{
    for (FDFireflyIceChannelUSB *channel in _usbTableViewDataSource.devices) {
        if (channel.device == device) {
            return channel;
        }
    }
    return nil;
}

- (void)usbHidMonitor:(FDUSBHIDMonitor *)monitor deviceRemoved:(FDUSBHIDDevice *)device
{
    FDFireflyIceChannelUSB *channel = [self channelForUSBDevice:device];

    for (FDFireflyIce *fireflyIce in _devices) {
        if (fireflyIce.channels[@"USB"] == channel) {
            [fireflyIce removeChannel:@"USB"];
            if (fireflyIce.channels[@"BLE"] == nil) {
                [_devices removeObject:fireflyIce];
            }
            break;
        }
    }

    [channel close];
    
    [_usbTableViewDataSource.devices removeObject:channel];
    [_usbTableView reloadData];
}

- (FDFireflyIceChannelUSB *)getSelectedUsbDevice
{
    NSInteger row = _usbTableView.selectedRow;
    if (row < 0) {
        return nil;
    }
    return [_usbTableViewDataSource.devices objectAtIndex:row];
}

- (IBAction)usbOpen:(id)sender
{
    FDFireflyIceChannelUSB *channel = [self getSelectedUsbDevice];
    [channel open];
}

- (IBAction)usbClose:(id)sender
{
    FDFireflyIceChannelUSB *channel = [self getSelectedUsbDevice];
    [channel close];
}

- (IBAction)usbSetTime:(id)sender
{
    FDFireflyIceChannelUSB *channel = [self getSelectedUsbDevice];
    FDFireflyIceCoder *coder = [[FDFireflyIceCoder alloc] init];
    [coder sendSetPropertyTime:channel time:[NSDate date]];
}

- (IBAction)usbProvision:(id)sender
{
    FDFireflyIceChannelUSB *channel = [self getSelectedUsbDevice];
    FDFireflyIceCoder *coder = [[FDFireflyIceCoder alloc] init];
    [coder sendProvision:channel dictionary:@{@"site":@"http://localhost:5000"} options:0];
}

- (IBAction)usbIndicate:(id)sender
{
    FDFireflyIceChannelUSB *channel = [self getSelectedUsbDevice];
    FDFireflyIceCoder *coder = [[FDFireflyIceCoder alloc] init];
    [coder sendIndicatorOverride:channel usbOrange:0 usbGreen:0 d0:0 d1:0xff0000 d2:0x00ff00 d3:0x0000ff d4:0 duration:5.0];
}

- (IBAction)usbSync:(id)sender
{
    FDFireflyIceChannelUSB *channel = [self getSelectedUsbDevice];
    FDFireflyIceCoder *coder = [[FDFireflyIceCoder alloc] init];
    [coder sendSyncStart:channel];
}

- (IBAction)usbReset:(id)sender
{
    FDFireflyIceChannelUSB *channel = [self getSelectedUsbDevice];
    FDFireflyIceCoder *coder = [[FDFireflyIceCoder alloc] init];
    [coder sendReset:channel type:FD_CONTROL_RESET_WATCHDOG];
}

- (FDFireflyIceChannelBLE *)getSelectedFireflyDevice
{
    NSInteger row = _bluetoothTableView.selectedRow;
    if (row < 0) {
        return nil;
    }
    return [_fireflyDevices objectAtIndex:row];
}

- (IBAction)bluetoothConnect:(id)sender
{
    FDFireflyIceChannelBLE *channel = [self getSelectedFireflyDevice];
    [_centralManager connectPeripheral:channel.peripheral options:nil];
}

- (IBAction)bluetoothSetTime:(id)sender
{
    FDFireflyIceChannelBLE *channel = [self getSelectedFireflyDevice];
    FDFireflyIceCoder *coder = [[FDFireflyIceCoder alloc] init];
    [coder sendSetPropertyTime:channel time:[NSDate date]];
}

- (IBAction)bluetoothProvision:(id)sender
{
    FDFireflyIceChannelBLE *channel = [self getSelectedFireflyDevice];
    FDFireflyIceCoder *coder = [[FDFireflyIceCoder alloc] init];
    [coder sendProvision:channel dictionary:@{@"site":@"http://localhost:5000"} options:0];
}

- (IBAction)bluetoothIndicate:(id)sender
{
    FDFireflyIceChannelBLE *channel = [self getSelectedFireflyDevice];
    FDFireflyIceCoder *coder = [[FDFireflyIceCoder alloc] init];
    [coder sendIndicatorOverride:channel usbOrange:0 usbGreen:0 d0:0 d1:0xffffff d2:0xffffff d3:0xffffff d4:0 duration:5.0];
}

- (IBAction)bluetoothSync:(id)sender
{
    FDFireflyIceChannelBLE *channel = [self getSelectedFireflyDevice];
    FDFireflyIceCoder *coder = [[FDFireflyIceCoder alloc] init];
    [coder sendSyncStart:channel];
}

- (IBAction)bluetoothStorage:(id)sender
{
    FDFireflyIceChannelBLE *channel = [self getSelectedFireflyDevice];
    FDFireflyIceCoder *coder = [[FDFireflyIceCoder alloc] init];
    [coder sendSetPropertyMode:channel mode:FD_CONTROL_MODE_STORAGE];
}

- (IBAction)bluetoothDisconnect:(id)sender
{
    FDFireflyIceChannelBLE *channel = [self getSelectedFireflyDevice];
    [_centralManager cancelPeripheralConnection:channel.peripheral];
}

- (IBAction)bluetoothReset:(id)sender
{
    FDFireflyIceChannelBLE *channel = [self getSelectedFireflyDevice];
    FDFireflyIceCoder *coder = [[FDFireflyIceCoder alloc] init];
    [coder sendReset:channel type:FD_CONTROL_RESET_SYSTEM_REQUEST];
}

- (IBAction)update:(id)sender
{
    FDFireflyIceChannelBLE *channel = [self getSelectedFireflyDevice];
    FDFireflyIce *fireflyIce = _devices[0];
    FDFirmwareUpdateTask *update = [[FDFirmwareUpdateTask alloc] init];
    update.fireflyIce = fireflyIce;
    update.channel = channel;
    NSString *path = @"/Users/denis/sandbox/denisbohm/firefly-ice-firmware/THUMB Flash Release/FireflyIce/FireflyIce.hex";
    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSMutableData *data = [NSMutableData dataWithData:[FDIntelHex parse:content address:0x08000 length:0x40000 - 0x08000]];
    // pad to sector multiple (firmware update expects full sectors)
    NSUInteger sectorSize = 4096;
    NSUInteger length = data.length;
    length = ((length + sectorSize - 1) / sectorSize) * sectorSize;
    data.length = length;
    update.firmware = data;
    [fireflyIce.executor execute:update];
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

- (FDFireflyIceChannelBLE *)getFireflyDeviceByPeripheral:(CBPeripheral *)peripheral
{
    for (FDFireflyIceChannelBLE *fireflyDevice in _fireflyDevices) {
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
    FDFireflyIceChannelBLE *fireflyDevice = [self getFireflyDeviceByPeripheral:peripheral];
    if (fireflyDevice != nil) {
        return;
    }

//    NSLog(@"didDiscoverPeripheral %@ ad=%@", peripheral, advertisementData);
    FDFireflyIce *fireflyIce = [[FDFireflyIce alloc] init];
    [fireflyIce.observable addObserver:self];
    FDFireflyIceChannelBLE *channelBLE = [[FDFireflyIceChannelBLE alloc] initWithPeripheral:peripheral];
    [fireflyIce addChannel:channelBLE type:@"BLE"];
    [_devices addObject:fireflyIce];
    [_fireflyDevices addObject:channelBLE];
    [_bluetoothTableView reloadData];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"didConnectPeripheral %@", peripheral.name);
    FDFireflyIceChannelBLE *fireflyDevice = [self getFireflyDeviceByPeripheral:peripheral];
    [fireflyDevice didConnectPeripheral];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"didDisconnectPeripheral %@ : %@", peripheral.name, error);
    FDFireflyIceChannelBLE *fireflyDevice = [self getFireflyDeviceByPeripheral:peripheral];
    [fireflyDevice didDisconnectPeripheralError:error];
}

@end
