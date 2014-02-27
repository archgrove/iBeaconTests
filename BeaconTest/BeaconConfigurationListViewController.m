//
//  BeaconConfigurationViewController.m
//  BeaconTest
//
//  Created by Adam Wright on 11/02/2014.
//  Copyright (c) 2014 Adam Wright. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "BeaconConfigurationListViewController.h"

typedef NS_ENUM(NSInteger, ConfigurationListSection)
{
    ConfigurationListUnknownSection,
    ConfigurationListBeaconSection,
    ConfigurationListNotBeaconSection
};

static const NSInteger ConfigurationListSectionCount = 3;
static NSArray *BeaconServiceUUIDs;

@implementation BeaconConfigurationListViewController
{
    CBCentralManager *centralManager;
    
    NSMutableArray *unknownDevices;
    NSMutableArray *beaconDevices;
    NSMutableArray *notBeaconDevices;
    
    BOOL shouldScan;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    static dispatch_once_t uuidSetup;
    dispatch_once(&uuidSetup, ^{
        BeaconServiceUUIDs = @[
                                [CBUUID UUIDWithString:@"0xFFF0"], // Beacon configuration service
                                [CBUUID UUIDWithString:@"0x180F"]  // Battery service
                              ];
    });
    
    
    unknownDevices = [NSMutableArray array];
    beaconDevices = [NSMutableArray array];
    notBeaconDevices = [NSMutableArray array];
    shouldScan = NO;
    
    centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    shouldScan = YES;
    
    if (centralManager.state == CBCentralManagerStatePoweredOn)
        [centralManager scanForPeripheralsWithServices:nil options:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (centralManager.state == CBCentralManagerStatePoweredOn)
        [centralManager stopScan];
    
    for (CBPeripheral *p in unknownDevices)
        [centralManager cancelPeripheralConnection:p];
    for (CBPeripheral *p in beaconDevices)
        [centralManager cancelPeripheralConnection:p];
    for (CBPeripheral *p in notBeaconDevices)
        [centralManager cancelPeripheralConnection:p];
    
    [unknownDevices removeAllObjects];
    [beaconDevices removeAllObjects];
    [notBeaconDevices removeAllObjects];
}

#pragma mark - CB Central manager delegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (shouldScan && central.state == CBCentralManagerStatePoweredOn)
        [central scanForPeripheralsWithServices:nil options:nil];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"Found peripheral %@", peripheral.name);
    [unknownDevices addObject:peripheral];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:ConfigurationListUnknownSection] withRowAnimation:UITableViewRowAnimationAutomatic];

    [central connectPeripheral:peripheral options:nil];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    peripheral.delegate = self;
    [peripheral discoverServices:BeaconServiceUUIDs];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSMutableArray *removeArray;
    NSInteger removeSection;
    
    if ([unknownDevices containsObject:peripheral])
    {
        removeArray = unknownDevices;
        removeSection = ConfigurationListUnknownSection;
    }
    if ([beaconDevices containsObject:peripheral])
    {
        removeArray = beaconDevices;
        removeSection = ConfigurationListBeaconSection;
    }

    if ([notBeaconDevices containsObject:peripheral])
    {
        removeArray = notBeaconDevices;
        removeSection = ConfigurationListNotBeaconSection;
    }

    NSInteger removeRow = [removeArray indexOfObject:peripheral];
    [removeArray removeObjectAtIndex:removeRow];
    
    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:removeRow inSection:removeSection]]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Peripheral delegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSInteger unknownIndex = [unknownDevices indexOfObject:peripheral];
    [unknownDevices removeObjectAtIndex:unknownIndex];

    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:unknownIndex inSection:ConfigurationListUnknownSection]]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
    
    if (error)
    {
        [notBeaconDevices addObject:peripheral];
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:(notBeaconDevices.count - 1) inSection:ConfigurationListNotBeaconSection]]
                                                 withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else
    {
        [beaconDevices addObject:peripheral];
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:(beaconDevices.count - 1) inSection:ConfigurationListBeaconSection]]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    for (id service in peripheral.services)
        [peripheral discoverCharacteristics:nil forService:service];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSLog(@"Got characteristics %@", service.characteristics);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return ConfigurationListSectionCount;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case ConfigurationListUnknownSection:
            return @"Discovering devices";
        case ConfigurationListBeaconSection:
            return @"Beacons";
        case ConfigurationListNotBeaconSection:
            return @"Not beacons";
        default:
            NSAssert(false, @"Unknown section");
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case ConfigurationListUnknownSection:
            return unknownDevices.count;
        case ConfigurationListBeaconSection:
            return beaconDevices.count;
        case ConfigurationListNotBeaconSection:
            return notBeaconDevices.count;
        default:
            NSAssert(false, @"Unknown section");
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    CBPeripheral *peripheral;
    
    switch (indexPath.section)
    {
        case ConfigurationListUnknownSection:
            cell = [tableView dequeueReusableCellWithIdentifier:@"ScanCell" forIndexPath:indexPath];
            cell.accessoryView = [[UIActivityIndicatorView alloc] init];
            peripheral = unknownDevices[indexPath.row];
            break;
        case ConfigurationListBeaconSection:
            cell = [tableView dequeueReusableCellWithIdentifier:@"BeaconCell" forIndexPath:indexPath];
            peripheral = beaconDevices[indexPath.row];
            break;
        case ConfigurationListNotBeaconSection:
            cell = [tableView dequeueReusableCellWithIdentifier:@"NotBeaconCell" forIndexPath:indexPath];
            peripheral = notBeaconDevices[indexPath.row];
            break;
        default:
            NSAssert(false, @"Unknown section");
    }
    
    cell.textLabel.text = peripheral.name;
    cell.detailTextLabel.text = peripheral.identifier.UUIDString;
    
    return cell;
}

@end
