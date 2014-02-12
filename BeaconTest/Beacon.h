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
@property (readonly) int major;
@property (readonly) int minor;
@property CLProximity proximity;
@property CLLocationAccuracy accuracy;

- (instancetype)initWithUUID:(NSUUID*)uuid major:(int)major minor:(int)minor;

@end
