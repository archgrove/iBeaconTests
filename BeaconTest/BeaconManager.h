//
//  BeaconManager.h
//  BeaconTest
//
//  Created by Adam Wright on 27/02/2014.
//  Copyright (c) 2014 Adam Wright. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Beacon.h"
#import "BeaconManagerDelegate.h"

typedef Beacon* (^BeaconConstructor)(NSUUID *uuid, NSInteger major, NSInteger minor);

@interface BeaconManager : NSObject<CLLocationManagerDelegate>

+ (instancetype)managerWithUUID:(NSUUID*)uuid;
+ (instancetype)managerWithUUIDString:(NSString*)uuidString;

@property (readonly) NSArray *allBeacons;
@property (readonly) NSUUID *UUID;
@property (readonly) BOOL isMonitoring;
@property NSTimeInterval beaconTimeout;
@property (strong) BeaconConstructor beaconConstructor;

@property (weak) id<BeaconManagerDelegate> delegate;

- (instancetype)initWithUUID:(NSUUID*)uuid;
- (void)startMonitoring;
- (void)stopMonitoring;

@end
