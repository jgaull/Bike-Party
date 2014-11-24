//
//  Ride.m
//  Bike Party
//
//  Created by Jon on 11/23/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import "Ride.h"

@interface Ride ()

@property (strong, nonatomic) NSMutableArray *mutableWaypoints;

@end

@implementation Ride

- (void)loadDirectionsWithCallback:(void (^)(GoogleDirectionsRoute *, NSError *))callback {
    
    if (self.routeRequiresRefresh) {
        
        NSMutableArray *path = [NSMutableArray new];
        for (Waypoint *waypoint in self.mutableWaypoints) {
            CLLocation *location = [[CLLocation alloc] initWithLatitude:waypoint.coordinate.latitude longitude:waypoint.coordinate.longitude];
            [path addObject:location];
        }
        
        GoogleDirectionsRequest *directions = [[GoogleDirectionsRequest alloc] initWithAPIKey:@"AIzaSyBHeXy9Im_mAQyCqugF8_kBdKnerpQ0kjE"];
        [directions loadDirectionsForPath:path WithCallback:^(NSArray *routes, NSError *error) {
            if (!error) {
                _route = routes.firstObject;
                _routeRequiresRefresh = NO;
            }
            
            callback(_route, error);
        }];
    }
    else {
        callback(_route, nil);
    }
}

- (Waypoint *)addDestinationWithCoordinate:(CLLocationCoordinate2D)coordinate {
    Waypoint *newDestination = [[Waypoint alloc] initWithType:WaypointTypeDestination coordinate:coordinate];
    
    [self.mutableWaypoints addObject:newDestination];
    
    _routeRequiresRefresh = YES;
    
    return newDestination;
}

- (void)removeDestination:(Waypoint *)destination {
    [self.mutableWaypoints removeObject:destination];
    
    _routeRequiresRefresh = YES;
}

- (void)replaceDestinationAtIndex:(NSInteger)index withDestination:(Waypoint *)destination {
    
    [self.mutableWaypoints replaceObjectAtIndex:index withObject:destination];
    
    _routeRequiresRefresh = YES;
}

- (void)replaceDestination:(Waypoint *)oldDestination withDestination:(Waypoint *)newDestination {
    NSUInteger index = [self.waypoints indexOfObject:oldDestination];
    [self replaceDestinationAtIndex:index withDestination:newDestination];
}

- (NSArray *)turnsForLeg:(GoogleDirectionsLeg *)leg {
    NSMutableArray *turns = [NSMutableArray new];
    
    for (GoogleDirectionsStep *step in leg.steps) {
        
        CLLocation *turnLocation = step.startLocation;
        Waypoint *turnWaypoint = [[Waypoint alloc] initWithType:WaypointTypeTurn coordinate:turnLocation.coordinate];
        
        [turns addObject:turnWaypoint];
    }
    
    return [NSArray arrayWithArray:turns];
}

- (NSArray *)allWaypoints {
    
    NSMutableArray *allWaypoints = [NSMutableArray new];
    
    for (GoogleDirectionsLeg *leg in self.route.legs) {
        
        NSUInteger index = [self.route.legs indexOfObject:leg];
        Waypoint *startWaypoint = [self.waypoints objectAtIndex:index];
        [allWaypoints addObject:startWaypoint];
        
        NSArray *turns = [self turnsForLeg:leg];
        [allWaypoints addObjectsFromArray:turns];
    }
    
    [allWaypoints addObject:self.waypoints.lastObject];
    
    return [NSArray arrayWithArray:allWaypoints];
}

- (NSMutableArray *)mutableWaypoints {
    if (!_mutableWaypoints) {
        _mutableWaypoints = [NSMutableArray new];
    }
    return _mutableWaypoints;
}

- (NSArray *)waypoints {
    return [NSArray arrayWithArray:self.mutableWaypoints];
}

@end
