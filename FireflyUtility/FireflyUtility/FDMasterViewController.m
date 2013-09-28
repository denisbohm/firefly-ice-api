//
//  FDMasterViewController.m
//  FireflyUtility
//
//  Created by Denis Bohm on 9/21/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDDetailTabBarController.h"
#import "FDDetailViewController.h"
#import "FDDevice.h"
#import "FDFireflyIceCollector.h"
#import "FDMasterViewController.h"

#import <FireflyDevice/FDFireflyIce.h>
#import <FireflyDevice/FDFireflyIceChannelBLE.h>

#if TARGET_OS_IPHONE
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif

@interface FDMasterViewController () <CBCentralManagerDelegate, FDFireflyIceObserver, UITabBarControllerDelegate, FDDetailTabBarControllerDelegate>

@property UITabBarController *tabBarController;

@property CBCentralManager *centralManager;
@property NSMutableArray *devices;

@property(nonatomic) FDDevice *device;

@end

@implementation FDMasterViewController

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    _devices = [NSMutableArray array];
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

- (FDFireflyIce *)getFireflyIceByPeripheral:(CBPeripheral *)peripheral
{
    for (FDDevice *device in _devices) {
        FDFireflyIce *fireflyIce = device.fireflyIce;
        FDFireflyIceChannelBLE *channel = fireflyIce.channels[@"BLE"];
        if (channel.peripheral == peripheral) {
            return fireflyIce;
        }
    }
    return nil;
}

- (FDDevice *)getDeviceByFireflyIce:(FDFireflyIce *)fireflyIce
{
    for (FDDevice *device in _devices) {
        if (device.fireflyIce == fireflyIce) {
            return device;
        }
    }
    return nil;
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    FDFireflyIce *fireflyIce = [self getFireflyIceByPeripheral:peripheral];
    if (fireflyIce != nil) {
        return;
    }
    
    fireflyIce = [[FDFireflyIce alloc] init];
    
    FDFireflyIceChannelBLE *channel = [[FDFireflyIceChannelBLE alloc] initWithPeripheral:peripheral];
    [fireflyIce addChannel:channel type:@"BLE"];
    
    FDFireflyIceCollector *collector = [[FDFireflyIceCollector alloc] init];
    collector.fireflyIce = fireflyIce;
    collector.channel = channel;
    
    FDDevice *device = [[FDDevice alloc] init];
    device.fireflyIce = fireflyIce;
    device.collector = collector;
    
    [_devices insertObject:device atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    FDFireflyIce *fireflyIce = [self getFireflyIceByPeripheral:peripheral];
    FDFireflyIceChannelBLE *channel = fireflyIce.channels[@"BLE"];
    [channel didConnectPeripheral];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    FDFireflyIce *fireflyIce = [self getFireflyIceByPeripheral:peripheral];
    FDFireflyIceChannelBLE *channel = fireflyIce.channels[@"BLE"];
    [channel didDisconnectPeripheralError:error];
}

- (void)connectBLE:(FDFireflyIce *)fireflyIce
{
    FDFireflyIceChannelBLE *channel = fireflyIce.channels[@"BLE"];
    [_centralManager connectPeripheral:channel.peripheral options:nil];
}

- (void)disconnectBLE:(FDFireflyIce *)fireflyIce
{
    FDFireflyIceChannelBLE *channel = fireflyIce.channels[@"BLE"];
    [_centralManager cancelPeripheralConnection:channel.peripheral];
}

- (IBAction)connect:(id)sender
{
    FDFireflyIce *fireflyIce = _device.fireflyIce;
    FDFireflyIceChannelBLE *channel = fireflyIce.channels[@"BLE"];
    if (channel.status == FDFireflyIceChannelStatusClosed) {
        [self connectBLE:fireflyIce];
    } else {
        [self disconnectBLE:fireflyIce];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _devices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    FDDevice *device = _devices[indexPath.row];
    cell.textLabel.text = [device.fireflyIce description];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        FDDevice *device = _devices[indexPath.row];
        self.device = device;
    }
}

- (void)configureConnectButton
{
    NSString *title = @"Connect";
    id<FDFireflyIceChannel> channel = _device.fireflyIce.channels[@"BLE"];
    switch (channel.status) {
        case FDFireflyIceChannelStatusClosed:
            title = @"Connect";
            break;
        case FDFireflyIceChannelStatusOpening:
            title = @"Cancel";
            break;
        case FDFireflyIceChannelStatusOpen:
            title = @"Disconnect";
            break;
    }
    UIBarButtonItem *connect = self.tabBarController.navigationItem.rightBarButtonItem;
    UIButton *connectButton = (UIButton *)connect.customView;
    [connectButton setTitle:title forState:UIControlStateNormal];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel status:(FDFireflyIceChannelStatus)status
{
    [self configureConnectButton];
    if (status == FDFireflyIceChannelStatusOpen) {
        FDDevice *device = [self getDeviceByFireflyIce:fireflyIce];
        if (device != nil) {
            [fireflyIce.executor execute:device.collector];
        }
    }
}

- (void)setDevice:(FDDevice *)device
{
    if (_device != device) {
        [_device.fireflyIce.observable removeObserver:self];
        
        _device = device;
        [_device.fireflyIce.observable addObserver:self];
        
        [self configureConnectButton];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        FDDetailTabBarController *tabBarController = (FDDetailTabBarController *)segue.destinationViewController;
        if (tabBarController != self.tabBarController) {
            self.tabBarController = tabBarController;
            self.tabBarController.delegate = self;
            UIBarButtonItem *connect = tabBarController.navigationItem.rightBarButtonItem;
            UIButton *connectButton = (UIButton *)connect.customView;
            [connectButton addTarget:self action:@selector(connect:) forControlEvents:UIControlEventTouchUpInside];
            tabBarController.detailTabBarControllerDelegate = self;
            [self configureConnectButton];
        }
        
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        self.device = _devices[indexPath.row];
        
        [self configureDetailView];
    }
}

- (void)detailTabBarControllerDidAppear:(FDDetailTabBarController *)detailTabBarController
{
    [self configureDetailView];
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    [self unconfigureDetailView];
    return YES;
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    [self configureDetailView];
}

- (void)configureDetailView
{
    FDDetailViewController *detailViewController = (FDDetailViewController *)self.tabBarController.selectedViewController;
    detailViewController.device = _device;
}

- (void)unconfigureDetailView
{
    FDDetailViewController *detailViewController = (FDDetailViewController *)self.tabBarController.selectedViewController;
    detailViewController.device = nil;
}

@end
