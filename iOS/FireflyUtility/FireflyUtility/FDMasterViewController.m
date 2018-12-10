//
//  FDMasterViewController.m
//  FireflyUtility
//
//  Created by Denis Bohm on 9/21/13.
//  Copyright (c) 2013 Firefly Design. All rights reserved.
//

#import "FDAppDelegate.h"
#import "FDDetailTabBarController.h"
#import "FDDetailViewController.h"
#import "FDFireflyIceCollector.h"
#import "FDHelpController.h"
#import "FDMasterViewController.h"

#import <FireflyDevice/FDFireflyIce.h>
#import <FireflyDevice/FDFireflyIceDeviceMock.h>
#import <FireflyDevice/FDFireflyIceChannelMock.h>
#import <FireflyDevice/FDFireflyIceCoder.h>
#import <FireflyDevice/FDFireflyIceManager.h>

#if TARGET_OS_IPHONE
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif

@interface FDMasterViewController () <FDFireflyIceManagerDelegate, FDHelpControllerDelegate>

@property FDDetailTabBarController *tabBarController;
@property FDHelpController *helpController;

@property FDFireflyIceManager *fireflyIceManager;

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

- (NSString *)helpText
{
    return
    @"Select a Firefly Ice device from the list to interact with it.\n\n"
    @"If you don't have a device yet but want to explore the interface select the 'Mock' device."
    ;
}

- (NSMutableDictionary *)makeMockDevice:(NSString *)name;
{
    FDFireflyIceDeviceMock *device = [[FDFireflyIceDeviceMock alloc] init];
    device.name = name;

    FDFireflyIce *fireflyIce = [[FDFireflyIce alloc] init];
    fireflyIce.name = device.name;

    FDFireflyIceChannelMock *channel = [[FDFireflyIceChannelMock alloc] init];
    channel.device = device;
    [fireflyIce addChannel:channel type:channel.name];
    
    FDFireflyIceCollector *collector = [[FDFireflyIceCollector alloc] init];
    collector.fireflyIce = fireflyIce;
    collector.channel = channel;

    return [NSMutableDictionary dictionaryWithDictionary:@{@"fireflyIce":fireflyIce, @"channel":channel, @"collector":collector}];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIApplication *application = [UIApplication sharedApplication];
    FDAppDelegate *appDelegate = (FDAppDelegate *)application.delegate;
    appDelegate.masterViewController = self;

    _helpController = [[FDHelpController alloc] init];
    _helpController.delegate = self;
    UIBarButtonItem *helpButtonItem = [_helpController makeBarButtonItem];
    self.navigationItem.rightBarButtonItems = @[helpButtonItem];

    NSArray<CBUUID *> *serviceUUIDs = @[
        [CBUUID UUIDWithString:@"310a0001-1b95-5091-b0bd-b7a681846399"], // Firefly Ice
        [CBUUID UUIDWithString:@"577FB8B4-553E-4807-9779-8647481D49B3"], // Atlas Wearable A101, A102
        [CBUUID UUIDWithString:@"39316b41-d4a3-be84-594d-4d0805f9d380"], // Atlas Wearable FIT
        [CBUUID UUIDWithString:@"2fa1a5ed-2c05-4bb2-9e4a-a7f16f1c395c"] // Atlas Wearable PET
    ];

    _fireflyIceManager = [FDFireflyIceManager managerWithServiceUUIDs:serviceUUIDs withDelegate:self];
    _devices = [NSMutableArray array];
  
// For making screen shots in the simulator. -denis
//    [_devices addObject:[self makeMockDevice:@"Firefly 43216789-BC01-F900"]];
    
    [_devices addObject:[self makeMockDevice:@"Mock"]];
}

- (void)viewDidAppear:(BOOL)animated
{
    _helpController.viewController = self;
    [_helpController autoShowHelp:NSStringFromClass([self class])];
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
    
    id<FDFireflyIceChannel> channel = fireflyIce.channels[@"BLE"];
    dictionary[@"channel"] = channel;
    
    FDFireflyIceChannelBLE *channelBle = (FDFireflyIceChannelBLE *)channel;
    channelBle.useL2cap = NO;
    
    FDFireflyIceCollector *collector = [[FDFireflyIceCollector alloc] init];
    collector.fireflyIce = fireflyIce;
    collector.channel = channel;
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
        self.tabBarController.device = device;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        FDDetailTabBarController *tabBarController = (FDDetailTabBarController *)segue.destinationViewController;
        if (tabBarController != self.tabBarController) {
            self.tabBarController = tabBarController;
            self.tabBarController.fireflyIceManager = _fireflyIceManager;
        }
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        tabBarController.device = _devices[indexPath.row];
    }
}

- (UIView *)helpControllerHelpView:(FDHelpController *)helpController
{
    UILabel *textView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    textView.backgroundColor = UIColor.clearColor;
    [textView setLineBreakMode:NSLineBreakByWordWrapping];
    textView.textColor = [UIColor whiteColor];
    
    NSMutableString *text = [NSMutableString stringWithString:[self helpText]];
    [text appendString:@"\n\nTouch the information button at the top right to hide or show this message."];
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *name = [bundle objectForInfoDictionaryKey:@"CFBundleName"];
    NSString *version = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *copyright = [bundle objectForInfoDictionaryKey:@"NSHumanReadableCopyright"];
    [text appendFormat:@"\n\n%@ v%@ %@", name, version, copyright];
    textView.text = text;
    
    textView.numberOfLines = 0;
    [textView sizeToFit];
    return textView;
}

@end
