//
//  Waypoint.m
//  Bike Party
//
//  Created by Jon on 11/20/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import "Waypoint.h"

@implementation Waypoint

- (id)initWithType:(WaypointType)type coordinate:(CLLocationCoordinate2D)coordinate {
    
    self = [super self];
    if (self) {
        _coordinate = coordinate;
        _type = type;
    }
    return self;
}

- (id)initWithType:(WaypointType)type coordinate:(CLLocationCoordinate2D)coordinate title:(NSString *)name {
    self = [super init];
    if (self) {
        _type = type;
        _title = name;
        _coordinate = coordinate;
    }
    return self;
}

@end
