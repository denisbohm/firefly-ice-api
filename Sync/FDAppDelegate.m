//
//  FDAppDelegate.m
//  Sync
//
//  Created by Denis Bohm on 4/3/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDAppDelegate.h"
#import "FDBinary.h"
#import "FDFireflyBle.h"
#import "FDFireflyUsb.h"
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

@interface FDAppDelegate () <CBCentralManagerDelegate, FDUSBHIDMonitorDelegate, FDFireflyDelegate, NSTableViewDataSource>

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
    
    [self setupGraph];
    
    [_usbMonitor start];
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
    id result = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
    NSArray *vmasArray = result[@"vmas"];
    [_activityPlotDataSource removeAll];
    for (NSDictionary *vmas in vmasArray) {
        uint32_t time = [vmas[@"time"] int32Value];
        uint16_t interval = [vmas[@"interval"] integerValue];
        NSArray *values = vmas[@"values"];
        for (NSNumber *value in values) {
            [_activityPlotDataSource addActivityTime:time value:[value doubleValue]];
            time += interval;
        }
    }
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)_activityGraph.defaultPlotSpace;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInteger(0) length:CPTDecimalFromInteger(10)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInteger(0) length:CPTDecimalFromInteger(10)];
}

- (void)usbHidMonitor:(FDUSBHIDMonitor *)monitor deviceAdded:(FDUSBHIDDevice *)device
{
    FDFireflyUsb *fireflyUsb = [[FDFireflyUsb alloc] initWithDevice:device];
    fireflyUsb.delegate = self;
    [_usbTableViewDataSource.devices addObject:fireflyUsb];
    [_usbTableView reloadData];
}

- (void)usbHidMonitor:(FDUSBHIDMonitor *)monitor deviceRemoved:(FDUSBHIDDevice *)device
{
    for (FDFireflyUsb *fireflyUsb in _usbTableViewDataSource.devices) {
        if (fireflyUsb.device == device) {
            [fireflyUsb close];
            
            [_usbTableViewDataSource.devices removeObject:fireflyUsb];
            [_usbTableView reloadData];
            
            break;
        }
    }
}

- (void)sync:(id<FDFirefly>)firefly data:(NSData *)data
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
    [firefly send:responseData];
}

- (void)sensing:(id<FDFirefly>)firefly data:(NSData *)data
{
    FDBinary *binary = [[FDBinary alloc] initWithData:data];
    float ax = [binary getFloat32];
    float ay = [binary getFloat32];
    float az = [binary getFloat32];
    float mx = [binary getFloat32];
    float my = [binary getFloat32];
    float mz = [binary getFloat32];
    
    _axSlider.floatValue = ax;
    _aySlider.floatValue = ay;
    _azSlider.floatValue = az;
    
    _mxSlider.floatValue = mx;
    _mySlider.floatValue = my;
    _mzSlider.floatValue = mz;
}

- (void)fireflyPacket:(id<FDFirefly>)firefly data:(NSData *)data
{
    FDBinary *binary = [[FDBinary alloc] initWithData:data];
    uint8_t code = [binary getUint8];
    switch (code) {
        case FD_SYNC_DATA:
            [self sync:firefly data:data];
            break;
        case 0xff:
            [self sensing:firefly data:[data subdataWithRange:NSMakeRange(1, data.length - 1)]];
            break;
    }
}

- (FDFireflyUsb *)getSelectedUsbDevice
{
    NSInteger row = _usbTableView.selectedRow;
    if (row < 0) {
        return nil;
    }
    return [_usbTableViewDataSource.devices objectAtIndex:row];
}

- (IBAction)usbOpen:(id)sender
{
    FDFireflyUsb *firefly = [self getSelectedUsbDevice];
    [firefly open];
}

- (IBAction)usbClose:(id)sender
{
    FDFireflyUsb *firefly = [self getSelectedUsbDevice];
    [firefly close];
}

- (IBAction)usbWrite:(id)sender
{
    FDFireflyUsb *firefly = [self getSelectedUsbDevice];
    uint8_t bytes[] = {FD_SYNC_START};
    [firefly send:[NSData dataWithBytes:&bytes length:sizeof(bytes)]];
}

- (FDFireflyBle *)getSelectedFireflyDevice
{
    NSInteger row = _bluetoothTableView.selectedRow;
    if (row < 0) {
        return nil;
    }
    return [_fireflyDevices objectAtIndex:row];
}

- (IBAction)bluetoothConnect:(id)sender
{
    FDFireflyBle *fireflyDevice = [self getSelectedFireflyDevice];
    fireflyDevice.delegate = self;
    [_centralManager connectPeripheral:fireflyDevice.peripheral options:nil];
}

- (IBAction)bluetoothWrite:(id)sender
{
    FDFireflyBle *firefly = [self getSelectedFireflyDevice];
    uint8_t bytes[] = {FD_SYNC_START};
    [firefly send:[NSData dataWithBytes:&bytes length:sizeof(bytes)]];
}


- (IBAction)bluetoothDisconnect:(id)sender
{
    FDFireflyBle *fireflyDevice = [self getSelectedFireflyDevice];
    fireflyDevice.delegate = nil;
    [_centralManager cancelPeripheralConnection:fireflyDevice.peripheral];
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

- (FDFireflyBle *)getFireflyDeviceByPeripheral:(CBPeripheral *)peripheral
{
    for (FDFireflyBle *fireflyDevice in _fireflyDevices) {
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
    FDFireflyBle *fireflyDevice = [self getFireflyDeviceByPeripheral:peripheral];
    if (fireflyDevice != nil) {
        return;
    }

    NSLog(@"didDiscoverPeripheral %@", peripheral);
    fireflyDevice = [[FDFireflyBle alloc] initWithPeripheral:peripheral];
    [_fireflyDevices addObject:fireflyDevice];
    
    [_bluetoothTableView reloadData];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"didConnectPeripheral %@", peripheral.name);
    FDFireflyBle *fireflyDevice = [self getFireflyDeviceByPeripheral:peripheral];
    [fireflyDevice didConnectPeripheral];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"didDisconnectPeripheral %@ : %@", peripheral.name, error);
    FDFireflyBle *fireflyDevice = [self getFireflyDeviceByPeripheral:peripheral];
    [fireflyDevice didDisconnectPeripheralError:error];
}


@end
