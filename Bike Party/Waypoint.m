//
//  Waypoint.m
//  Bike Party
//
//  Created by Jon on 11/20/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import "Waypoint.h"

@implementation Waypoint

- (id)initWithWaypoint:(Waypoint *)waypoint {
    self = [super init];
    if (self) {
        _coordinate = waypoint.coordinate;
        _type = waypoint.type;
        _title = waypoint.title;
    }
    return self;
}

- (id)initWithType:(WaypointType)type coordinate:(CLLocationCoordinate2D)coordinate {
    
    self = [super init];
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

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[Waypoint class]]) {
        
        Waypoint *otherWaypoint = (Waypoint *)object;
        
        if (otherWaypoint.coordinate.latitude == self.coordinate.latitude &&
            otherWaypoint.coordinate.longitude == self.coordinate.longitude &&
            [otherWaypoint.title isEqualToString:self.title] &&
            [otherWaypoint.subtitle isEqualToString:self.subtitle] &&
            otherWaypoint.type == self.type) {
            
            return YES;
        }
    }
    
    return NO;
}

@end
