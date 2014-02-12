//
//  MasterViewController.m
//  BeaconTest
//
//  Created by Adam Wright on 10/02/2014.
//  Copyright (c) 2014 Adam Wright. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#import "BeaconListViewController.h"

@interface Beacon : NSObject

@property (readonly) NSUUID *uuid;
@property (readonly) int major;
@property (readonly) int minor;
@property CLProximity proximity;
@property CLLocationAccuracy accuracy;

- (instancetype)initWithUUID:(NSUUID*)uuid major:(int)major minor:(int)minor proximity:(CLProximity)proximity;

@end

@implementation Beacon

- (instancetype)initWithUUID:(NSUUID*)uuid major:(int)major minor:(int)minor proximity:(CLProximity)proximity
{
    self = [super init];
    
    if (self)
    {
        _uuid = uuid;
        _major = major;
        _minor = minor;
        _proximity = proximity;
    }
    
    return self;
}

- (BOOL)isEqual:(id)object
{
    if (object == nil || ![object isKindOfClass:[Beacon class]])
          return NO;
    
    Beacon *rhs = (Beacon*)object;
    
    return (rhs.major == self.major && rhs.minor == self.minor && [rhs.uuid isEqual:self.uuid]);
}

@end


@implementation BeaconListViewController
{
    CLLocationManager *_locationManager;
    CLBeaconRegion *_beaconRegion;
    
    NSMutableArray *_beacons;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSString * const BeaconID = @"EBEFD083-70A2-47C8-9837-E7B5634DF524";
    NSUUID * const BeaconUUID = [[NSUUID alloc] initWithUUIDString:BeaconID];
    
    _beacons = [NSMutableArray array];
    
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    
    _beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:BeaconUUID identifier:@"Beacons"];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [_locationManager startMonitoringForRegion:_beaconRegion];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [_locationManager stopMonitoringForRegion:_beaconRegion];
    [_locationManager stopRangingBeaconsInRegion:_beaconRegion];
}

#pragma mark - Table view delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _beacons.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BeaconCell" forIndexPath:indexPath];

    Beacon *beacon = _beacons[indexPath.row];
    
    NSString *proxString = nil;
    
    switch (beacon.proximity)
    {
        case CLProximityUnknown:
            proxString = @"at unknown distance";
            break;
        case CLProximityFar:
            proxString = @"far away";
            break;
        case CLProximityImmediate:
            proxString = @"very close";
            break;
        case CLProximityNear:
            proxString = @"nearby";
            break;
    }

    cell.textLabel.text = [NSString stringWithFormat:@"Beacon %d.%d is %@ (%f)", beacon.major, beacon.minor, proxString, beacon.accuracy];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", beacon.uuid.UUIDString];
    
    return cell;
}

#pragma mark - Location manager delegate

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    NSLog(@"Entered region %@", region.identifier);
    
    [_locationManager startRangingBeaconsInRegion:_beaconRegion];
}

- (void)locationManager:(CLLocationManager *)manager
	  didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    NSString *stateString;
    
    if (state == CLRegionStateInside)
        stateString = @"Inside";
    else if (state == CLRegionStateOutside)
        stateString = @"Outside";
    else
        stateString = @"Unknown";
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    for (CLBeacon *clBeacon in beacons)
    {
        // One of the 
        if (clBeacon.proximity == CLProximityUnknown)
            continue;
        
        Beacon *beacon = [[Beacon alloc] initWithUUID:clBeacon.proximityUUID major:clBeacon.major.intValue minor:clBeacon.minor.intValue proximity:clBeacon.proximity];
    

        if ([_beacons containsObject:beacon])
        {
            NSInteger index = [_beacons indexOfObject:beacon];
            [_beacons[index] setProximity:clBeacon.proximity];
            [_beacons[index] setAccuracy:clBeacon.accuracy];
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        else
        {
            [_beacons addObject:beacon];
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:(_beacons.count - 1) inSection:0]]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}

@end