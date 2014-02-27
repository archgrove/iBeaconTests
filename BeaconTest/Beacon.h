//
//  Beacon.h
//  BeaconTest
//
//  Created by Adam Wright on 12/02/2014.
//  Copyright (c) 2014 Adam Wright. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface Beacon : NSObject

@property (readonly) NSUUID *uuid;
@property (readonly) NSInteger major;
@property (readonly) NSInteger minor;

@property CLProximity proximity;
@property CLLocationAccuracy accuracy;
@property NSInteger RSSI;
@property NSTimeInterval lastSeenTime;

- (instancetype)initWithUUID:(NSUUID*)uuid major:(NSInteger)major minor:(NSInteger)minor;

- (CGFloat)estimateDistanceFromTXPower:(CGFloat)txPower;
- (CGFloat)linearPowerFromTXPower:(CGFloat)txPower;

@end
