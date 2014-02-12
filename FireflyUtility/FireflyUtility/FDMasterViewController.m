//
//  FDMasterViewController.m
//  FireflyUtility
//
//  Created by Denis Bohm on 9/21/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDDetailTabBarController.h"
#import "FDDetailViewController.h"
#import "FDFireflyIceCollector.h"
#import "FDMasterViewController.h"

#import <FireflyDevice/FDFireflyIce.h>
#import <FireflyDevice/FDFireflyIceChannelBLE.h>
#import <FireflyDevice/FDFireflyIceCoder.h>
#import <FireflyDevice/FDFireflyIceManager.h>

#if TARGET_OS_IPHONE
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif

@interface FDMasterViewController () <FDFireflyIceManagerDelegate, FDFireflyIceObserver, UITabBarControllerDelegate, FDDetailTabBarControllerDelegate, UINavigationControllerDelegate>

@property UITabBarController *tabBarController;

@property FDFireflyIceManager *fireflyIceManager;

@property NSMutableArray *devices;
@property(nonatomic) NSMutableDictionary *device;

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

- (NSMutableDictionary *)makeFakeDevice
{
    FDFireflyIce *fireflyIce = [[FDFireflyIce alloc] init];
    fireflyIce.name = @"Firefly 43216789-BC01-F900";

    FDFireflyIceCollector *collector = [[FDFireflyIceCollector alloc] init];
    collector.fireflyIce = fireflyIce;
    
    [collector setEntry:@"name" object:@"Firefly"];
    
    FDFireflyIceVersion *version = [[FDFireflyIceVersion alloc] init];
    version.major = 1;
    version.minor = 0;
    version.patch = 10;
    version.capabilities = FD_CONTROL_CAPABILITY_LOCK |
        FD_CONTROL_CAPABILITY_BOOT_VERSION |
        FD_CONTROL_CAPABILITY_SYNC_FLAGS |
        FD_CONTROL_CAPABILITY_SYNC_AHEAD |
        FD_CONTROL_CAPABILITY_IDENTIFY |
        FD_CONTROL_CAPABILITY_LOGGING |
        FD_CONTROL_CAPABILITY_DIAGNOSTICS;
    [collector setEntry:@"version" object:version];
    
    FDFireflyIceVersion *bootVersion = [[FDFireflyIceVersion alloc] init];
    bootVersion.major = 1;
    bootVersion.minor = 2;
    bootVersion.patch = 3;
    [collector setEntry:@"bootVersion" object:bootVersion];
    
    FDFireflyIceHardwareId *hardwareId = [[FDFireflyIceHardwareId alloc] init];
    hardwareId.vendor = 0x2333;
    hardwareId.product = 0x0002;
    hardwareId.major = 1;
    hardwareId.minor = 3;
    uint8_t bytes[8] = {0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08};
    hardwareId.unique = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    [collector setEntry:@"hardwareId" object:hardwareId];
    
    [collector setEntry:@"debugLock" object:[NSNumber numberWithBool:NO]];
    
    [collector setEntry:@"time" object:[NSDate dateWithTimeIntervalSinceNow:-1.2]];
    
    FDFireflyIcePower *power = [[FDFireflyIcePower alloc] init];
    power.batteryLevel = 0.87;
    power.batteryVoltage = 4.05;
    power.isUSBPowered = YES;
    power.isCharging = YES;
    power.chargeCurrent = 0.017;
    power.temperature = 19.8;
    [collector setEntry:@"power" object:power];
    
    FDFireflyIceReset *reset = [[FDFireflyIceReset alloc] init];
    reset.cause = 64;
    reset.date = [NSDate dateWithTimeIntervalSinceNow:-7 * 24 * 60 *60];
    [collector setEntry:@"reset" object:reset];
    
    FDFireflyIceStorage *storage = [[FDFireflyIceStorage alloc] init];
    storage.pageCount = 0;
    [collector setEntry:@"storage" object:storage];
    
    [collector setEntry:@"txPower" object:[NSNumber numberWithInt:2]];
    
    FDFireflyIceDirectTestModeReport *report = [[FDFireflyIceDirectTestModeReport alloc] init];
    report.packetCount = 0x8000 | 1081;
    [collector setEntry:@"directTestModeReport" object:report];
    
    /*
    @"fireflyIce:channel:site:",
    @"fireflyIce:channel:sensing:",
    */
    
    return [NSMutableDictionary dictionaryWithDictionary:@{@"fireflyIce":fireflyIce, @"collector":collector}];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    _fireflyIceManager = [FDFireflyIceManager managerWithDelegate:self];
    _devices = [NSMutableArray array];
    
    // !!! just for testing -denis
    [_devices addObject:[self makeFakeDevice]];
}

- (FDFireflyIce *)getFireflyIceByPeripheral:(CBPeripheral *)peripheral
{
    NSDictionary *dictionary = [_fireflyIceManager dictionaryFor:peripheral key:@"peripheral"];
    return dictionary[@"fireflyIce"];
}

- (FDFireflyIceCollector *)getCollectorByFireflyIce:(FDFireflyIce *)fireflyIce
{
    NSDictionary *dictionary = [_fireflyIceManager dictionaryFor:fireflyIce key:@"fireflyIce"];
    return dictionary[@"collector"];
}

- (void)fireflyIceManager:(FDFireflyIceManager *)manager discovered:(FDFireflyIce *)fireflyIce
{
    NSMutableDictionary *dictionary = [manager dictionaryFor:fireflyIce key:@"fireflyIce"];
    
    FDFireflyIceCollector *collector = [[FDFireflyIceCollector alloc] init];
    collector.fireflyIce = fireflyIce;
    collector.channel = fireflyIce.channels[@"BLE"];
    dictionary[@"collector"] = collector;
    
    [_devices insertObject:dictionary atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (NSIndexPath *)indexPathForFireflyIce:(FDFireflyIce *)fireflyIce
{
    for (NSUInteger i = 0; i < _devices.count; ++i) {
        NSDictionary *dictionary = _devices[i];
        if (dictionary[@"fireflyIce"] == fireflyIce) {
            return [NSIndexPath indexPathForRow:i inSection:0];
        }
    }
    return nil;
}

- (void)fireflyIceManager:(FDFireflyIceManager *)manager advertisementDataHasChanged:(FDFireflyIce *)fireflyIce
{
    NSIndexPath *indexPath = [self indexPathForFireflyIce:fireflyIce];
    if (indexPath != nil) {
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (IBAction)connect:(id)sender
{
    FDFireflyIce *fireflyIce = _device[@"fireflyIce"];
    id<FDFireflyIceChannel> channel = fireflyIce.channels[@"BLE"];
    if (channel.status == FDFireflyIceChannelStatusClosed) {
        [_fireflyIceManager connectBLE:fireflyIce];
    } else {
        [_fireflyIceManager disconnectBLE:fireflyIce];
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

    NSMutableDictionary *device = _devices[indexPath.row];
    FDFireflyIce *fireflyIce = device[@"fireflyIce"];
    cell.textLabel.text = [fireflyIce description];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        NSMutableDictionary *device = _devices[indexPath.row];
        self.device = device;
    }
}

- (void)configureConnectButton
{
    NSString *title = @"Connect";
    FDFireflyIce *fireflyIce = _device[@"fireflyIce"];
    id<FDFireflyIceChannel> channel = fireflyIce.channels[@"BLE"];
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
    [connectButton setEnabled:channel != nil];
}

- (void)fireflyIce:(FDFireflyIce *)fireflyIce channel:(id<FDFireflyIceChannel>)channel status:(FDFireflyIceChannelStatus)status
{
    [self configureConnectButton];
    if (status == FDFireflyIceChannelStatusOpen) {
        NSMutableDictionary *device = [_fireflyIceManager dictionaryFor:fireflyIce key:@"fireflyIce"];
        if (device != nil) {
            FDFireflyIceCollector *collector = device[@"collector"];
            [fireflyIce.executor execute:collector];
        }
    }
}

- (void)fireflyIceManager:(FDFireflyIceManager *)manager identified:(FDFireflyIce *)fireflyIce
{
//    [fireflyIce.executor execute:[FDSyncTask syncTask:fireflyIce channel:fireflyIce.channels[@"BLE"]]];
}

- (void)setDevice:(NSMutableDictionary *)device
{
    if (_device != device) {
        FDFireflyIce *fireflyIce = _device[@"fireflyIce"];
        [fireflyIce.observable removeObserver:self];
        
        _device = device;
        fireflyIce = _device[@"fireflyIce"];
        [fireflyIce.observable addObserver:self];
        
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
    if ([viewController isKindOfClass:[FDDetailViewController class]]) {
        [self configureDetailView];
    } else
    if (viewController == self.tabBarController.moreNavigationController) {
        self.tabBarController.moreNavigationController.delegate = self;
    }
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [self configureDetailView];
}

- (FDDetailViewController *)selectedDetailViewController
{
    id viewController = self.tabBarController.selectedViewController;
    if (viewController == self.tabBarController.moreNavigationController) {
        return nil;
    }
    if ([viewController isKindOfClass:[FDDetailViewController class]]) {
        return (FDDetailViewController *)viewController;
    }
    return nil;
}

- (void)configureDetailView
{
    FDDetailViewController *detailViewController = [self selectedDetailViewController];
    detailViewController.device = _device;
    [detailViewController configureView];
    NSLog(@"configure %@", NSStringFromClass([detailViewController class]));
}

- (void)unconfigureDetailView
{
    FDDetailViewController *detailViewController = [self selectedDetailViewController];
    detailViewController.device = nil;
    NSLog(@"unconfigure %@", NSStringFromClass([detailViewController class]));
}

@end
