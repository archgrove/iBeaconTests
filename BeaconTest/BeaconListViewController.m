//
//  MasterViewController.m
//  BeaconTest
//
//  Created by Adam Wright on 10/02/2014.
//  Copyright (c) 2014 Adam Wright. All rights reserved.
//

#import "BeaconListViewController.h"

#import "BeaconManager.h"

@implementation BeaconListViewController
{
    BeaconManager *_beaconManager;
    
    NSMutableArray *_beacons;
    
    __weak IBOutlet UITableView *_tableView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSString * const BeaconID = @"EBEFD083-70A2-47C8-9837-E7B5634DF524";
    _beaconManager = [BeaconManager managerWithUUIDString:BeaconID];
    _beaconManager.delegate = self;
    
    _beacons = [NSMutableArray array];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [_beaconManager startMonitoring];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [_beaconManager stopMonitoring];
    [_beacons removeAllObjects];
    [_tableView reloadData];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BeaconCell"];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"BeaconCell"];
    }

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

- (void)beaconManager:(BeaconManager *)beaconManager discoveredBeacon:(Beacon *)newBeacon
{
    [_beacons addObject:newBeacon];
    NSInteger index = [_beacons indexOfObject:newBeacon];
    
    [_tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
                      withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)beaconManager:(BeaconManager *)beaconManager lostBeacon:(Beacon *)lostBeacon
{
    NSInteger index = [_beacons indexOfObject:lostBeacon];
    [_beacons removeObjectAtIndex:index];
    
    [_tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
                      withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)beaconManager:(BeaconManager *)beaconManager updatedBeacon:(Beacon *)beacon
{
    NSInteger index = [_beacons indexOfObject:beacon];
    
    [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
                      withRowAnimation:UITableViewRowAnimationAutomatic];
}
@end
