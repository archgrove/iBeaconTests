//
//  BeaconManager.m
//  BeaconTest
//
//  Created by Adam Wright on 27/02/2014.
//  Copyright (c) 2014 Adam Wright. All rights reserved.
//

#import "BeaconManager.h"
#import <CoreLocation/CoreLocation.h>

@implementation BeaconManager
{
    CLLocationManager *_locationManager;
    CLBeaconRegion *_beaconRegion;
    
    NSMutableArray *_beacons;
}

+ (instancetype)managerWithUUID:(NSUUID*)uuid
{
    return [[BeaconManager alloc] initWithUUID:uuid];
}

+ (instancetype)managerWithUUIDString:(NSString*)uuidString
{
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
    
    return [[BeaconManager alloc] initWithUUID:uuid];
}

- (instancetype)initWithUUID:(NSUUID*)uuid
{
    self = [super init];
    
    if (self)
    {
        _UUID = uuid;
        _isMonitoring = NO;
        _beaconTimeout = [[NSDate distantFuture] timeIntervalSinceReferenceDate];
        
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        
        _beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:@"Beacons"];
        
        _beacons = [NSMutableArray array];
    }
    
    return self;
}

- (void)dealloc
{
    [self cancelTimeoutCallback];
    
    // Stop monitoring
    [self stopMonitoring];
}

- (void)startMonitoring
{
    if (!_isMonitoring)
    {
        _isMonitoring = YES;
        
        [_locationManager startMonitoringForRegion:_beaconRegion];
    }
}

- (void)stopMonitoring
{
    if (_isMonitoring)
    {
        _isMonitoring = NO;
        
        [self cancelTimeoutCallback];
        [_locationManager stopMonitoringForRegion:_beaconRegion];
        [_locationManager stopRangingBeaconsInRegion:_beaconRegion];
        [_beacons removeAllObjects];
    }
}

- (NSArray*)allBeacons
{
    return _beacons;
}

#pragma region - Core location delegates

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    [_locationManager startRangingBeaconsInRegion:_beaconRegion];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    // When we exit a region, we send the lost beacon notifications to the delegate
    [self loseBeacons:_beacons];

    [_locationManager stopRangingBeaconsInRegion:_beaconRegion];
}

- (void)locationManager:(CLLocationManager *)manager
	  didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    for (CLBeacon *clBeacon in beacons)
    {
        // One of the oddities of the chinese beacons is we often get unknown data points interspersed in the real data
        if (clBeacon.proximity == CLProximityUnknown)
            continue;
        
        NSInteger currentIndex = [_beacons indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            Beacon *b = (Beacon*)obj;
            
            return (   [b.uuid isEqual:clBeacon.proximityUUID]
                    && b.major == clBeacon.major.intValue
                    && b.minor == clBeacon.minor.intValue);
        }];
        
        if (currentIndex != NSNotFound)
        {
            // We've seen this beacon before
            [_beacons[currentIndex] setProximity:clBeacon.proximity];
            [_beacons[currentIndex] setAccuracy:clBeacon.accuracy];
            [_beacons[currentIndex] setRSSI:clBeacon.rssi];
            [_beacons[currentIndex] setLastSeenTime:[NSDate timeIntervalSinceReferenceDate]];
            
            if ([_delegate respondsToSelector:@selector(beaconManager:updatedBeacon:)])
                [_delegate beaconManager:self updatedBeacon:_beacons[currentIndex]];
        }
        else
        {
            // This is a new beacon!
            Beacon *b;
            
            if (!self.beaconConstructor)
            {
                b = [[Beacon alloc] initWithUUID:clBeacon.proximityUUID
                                           major:clBeacon.major.integerValue
                                           minor:clBeacon.minor.integerValue];
            }
            else
            {
                b = self.beaconConstructor(clBeacon.proximityUUID, clBeacon.major.integerValue, clBeacon.minor.integerValue);
            }
            
            b.proximity = clBeacon.proximity;
            b.accuracy = clBeacon.accuracy;
            b.RSSI = clBeacon.rssi;
            b.lastSeenTime = [NSDate timeIntervalSinceReferenceDate];
            
            [_beacons addObject:b];
            
            if ([_delegate respondsToSelector:@selector(beaconManager:discoveredBeacon:)])
                [_delegate beaconManager:self discoveredBeacon:b];
        }
    }
    
    // Update the timeout callbacks
    [self scheduleTimeoutCallback];
}                   

- (void)scheduleTimeoutCallback
{
    // Setup the callback to timeout the next beacon due, after clearing the current callback
    [self cancelTimeoutCallback];
    
    
    NSTimeInterval nextCallback = [[NSDate distantFuture] timeIntervalSinceReferenceDate];
    BOOL shouldTimeout = NO;
    
    for (Beacon *b in _beacons)
    {
        if (b.lastSeenTime + self.beaconTimeout < nextCallback)
        {
            nextCallback = b.lastSeenTime + self.beaconTimeout;
            shouldTimeout = YES;
        }
    }
    
    if (shouldTimeout)
    {
        [self performSelector:@selector(killTimedOutBeacons) withObject:nil
                   afterDelay:nextCallback - [NSDate timeIntervalSinceReferenceDate]];
    }
    else
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
    }
}

- (void)cancelTimeoutCallback
{
    // Prevent future timeout callbacks
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(killTimedOutBeacons) object:nil];
}

- (void)loseBeacons:(NSArray*)beaconsToLose
{
    // Lose any beacons in an array
    if ([_delegate respondsToSelector:@selector(beaconManager:lostBeacon:)])
    {
        for (Beacon *b in beaconsToLose)
        {
            [_beacons removeObject:b];
            [_delegate beaconManager:self lostBeacon:b];
        }
    }
    else
    {
        [_beacons removeObjectsInArray:beaconsToLose];
    }
}

- (void)killTimedOutBeacons
{
    // Remove any timed out beacons
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    [self loseBeacons:[_beacons filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(Beacon *b, NSDictionary *bindings) {
        return (b.lastSeenTime + self.beaconTimeout < now);
    }]]];
}

@end
