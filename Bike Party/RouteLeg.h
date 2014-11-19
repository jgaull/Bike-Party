//
//  RouteLeg.h
//  Bike Party
//
//  Created by Jon on 11/14/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "GooglePlace.h"
#import "GoogleDirectionsRoute.h"

@interface RouteLeg : NSObject

@property (strong, nonatomic) GooglePlace *startPlace;
@property (strong, nonatomic) GooglePlace *endPlace;
@property (strong, nonatomic) NSMutableArray *waypoints;

- (void)removeWaypoint:(CLLocation *)waypointLocation;

- (CLLocation *)findWaypointWithCoordinate:(CLLocationCoordinate2D)waypointCoordinate;

- (void)loadDirectionsWithCallback:(void (^)(GoogleDirectionsRoute *route, NSError *error))callback;

@end
