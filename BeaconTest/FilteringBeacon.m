//
//  FilteringBeacon.m
//  BeaconTest
//
//  Created by Adam Wright on 27/02/2014.
//  Copyright (c) 2014 Adam Wright. All rights reserved.
//

#import "FilteringBeacon.h"

@implementation FilteringBeacon
{
    NSArray *previousRSSIs;
    NSTimeInterval lastTime;
    
    NSMutableArray *lastRSSIs;
    
}

- (instancetype)initWithUUID:(NSUUID *)uuid major:(NSInteger)major minor:(NSInteger)minor
{
    self = [super initWithUUID:uuid major:major minor:minor];
    
    if (self)
    {
        lastTime = [[NSDate distantPast] timeIntervalSinceReferenceDate];

        self.maxRSSI = 5;
        lastRSSIs = [NSMutableArray arrayWithCapacity:self.maxRSSI];
    }
    
    return self;
}

- (void)setRSSI:(NSInteger)RSSI
{
    // We use a simple 5-pass rolling average to determine the RSSI
    // TODO: We should shift to a 1D Kalman filter, and estimate the error distribution based on emperial samples    
    lastTime = [NSDate timeIntervalSinceReferenceDate];
    
    if (lastRSSIs.count == self.maxRSSI)
        [lastRSSIs removeObjectAtIndex:0];
    [lastRSSIs addObject:@(RSSI)];
    
    NSInteger rssiSum = 0;
    for (NSNumber *n in lastRSSIs)
        rssiSum += [n integerValue];
    
    [super setRSSI:rssiSum / lastRSSIs.count];
}

@end
