//
//  BeaconDelegate.h
//  BeaconTest
//
//  Created by Adam Wright on 27/02/2014.
//  Copyright (c) 2014 Adam Wright. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BeaconManager;
@class Beacon;

@protocol BeaconManagerDelegate <NSObject>

@optional

- (void)beaconManager:(BeaconManager*)beaconManager discoveredBeacon:(Beacon*)newBeacon;
- (void)beaconManager:(BeaconManager*)beaconManager lostBeacon:(Beacon*)lostBeacon;
- (void)beaconManager:(BeaconManager*)beaconManager updatedBeacon:(Beacon*)beacon;

@end
