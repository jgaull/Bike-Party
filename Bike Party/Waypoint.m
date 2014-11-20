//
//  Waypoint.m
//  Bike Party
//
//  Created by Jon on 11/20/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import "Waypoint.h"

@implementation Waypoint

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate andName:(NSString *)name {
    self = [super self];
    if (self) {
        self.coordinate = coordinate;
        self.name = name;
    }
    return self;
}

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate {
    self = [super self];
    if (self) {
        self.coordinate = coordinate;
    }
    return self;
}

@end
