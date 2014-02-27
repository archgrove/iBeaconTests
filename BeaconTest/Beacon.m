//
//  Beacon.m
//  BeaconTest
//
//  Created by Adam Wright on 12/02/2014.
//  Copyright (c) 2014 Adam Wright. All rights reserved.
//

#import "Beacon.h"

@implementation Beacon
{
    
}

- (instancetype)initWithUUID:(NSUUID*)uuid major:(NSInteger)major minor:(NSInteger)minor
{
    self = [super init];
    
    if (self)
    {
        _uuid = uuid;
        _major = major;
        _minor = minor;
    }
    
    return self;
}

- (CGFloat)estimateDistanceFromTXPower:(CGFloat)txPower
{
    return sqrt([self linearPowerFromTXPower:txPower]);
}

- (CGFloat)linearPowerFromTXPower:(CGFloat)txPower
{
    CGFloat dbRatio = self.RSSI - txPower;
    return pow(dbRatio / 10, 10);
}

@end
