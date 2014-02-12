//
//  Beacon.m
//  BeaconTest
//
//  Created by Adam Wright on 12/02/2014.
//  Copyright (c) 2014 Adam Wright. All rights reserved.
//

#import "Beacon.h"

@implementation Beacon

- (instancetype)initWithUUID:(NSUUID*)uuid major:(int)major minor:(int)minor
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

@end
