//
//  RideLeg.h
//  Bike Party
//
//  Created by Jon on 11/23/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "GoogleDirectionsRequest.h"
#import "Waypoint.h"

@interface RideLeg : NSObject

- (id)initWithStartWaypoint:(Waypoint *)startWaypoint;
- (id)initWithStartWaypoint:(Waypoint *)startWaypoint andEndWaypoint:(Waypoint *)endWaypoint;

- (void)loadDirectionsWithCallback:(void (^)(GoogleDirectionsRoute *, NSError *))callback;

@property (strong, nonatomic) GoogleDirectionsRoute *route;
@property (strong, nonatomic) NSArray *waypoints;
@property (readonly, nonatomic) Waypoint *startDestination;
@property (readonly, nonatomic) Waypoint *endDestination;

@end
