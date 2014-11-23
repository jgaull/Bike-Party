//
//  Ride.h
//  Bike Party
//
//  Created by Jon on 11/23/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "RideLeg.h"

@interface Ride : NSObject

@property (readonly, nonatomic) GoogleDirectionsRoute *route;
@property (readonly, nonatomic) NSArray *waypoints;
@property (readonly, nonatomic) NSArray *allWaypoints;

- (Waypoint *)addDestinationWithCoordinate:(CLLocationCoordinate2D)coordinate;
- (void)removeDestination:(Waypoint *)destination;
- (void)replaceDestinationAtIndex:(NSInteger)index withDestination:(Waypoint *)destination;

- (void)loadDirectionsWithCallback:(void (^)(GoogleDirectionsRoute *route, NSError *error))callback;

@end
