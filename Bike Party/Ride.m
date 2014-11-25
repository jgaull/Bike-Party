//
//  Ride.m
//  Bike Party
//
//  Created by Jon on 11/23/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import "Ride.h"

@interface Ride ()

@property (strong, nonatomic) NSMutableArray *mutableDestinations;

@end

@implementation Ride

- (void)loadDirectionsWithCallback:(void (^)(GoogleDirectionsRoute *, NSError *))callback {
    
    if (self.routeRequiresRefresh) {
        
        NSMutableArray *path = [NSMutableArray new];
        for (Waypoint *waypoint in self.destinations) {
            CLLocation *location = [[CLLocation alloc] initWithLatitude:waypoint.coordinate.latitude longitude:waypoint.coordinate.longitude];
            [path addObject:location];
        }
        
        GoogleDirectionsRequest *directions = [[GoogleDirectionsRequest alloc] initWithAPIKey:@"AIzaSyBHeXy9Im_mAQyCqugF8_kBdKnerpQ0kjE"];
        [directions loadDirectionsForPath:path WithCallback:^(NSArray *routes, NSError *error) {
            if (!error) {
                _route = routes.firstObject;
                _routeRequiresRefresh = NO;
            }
            else {
                _route = nil;
            }
            
            callback(_route, error);
        }];
    }
    else {
        callback(_route, nil);
    }
}

- (Waypoint *)addDestinationWithCoordinate:(CLLocationCoordinate2D)coordinate {
    
    NSInteger legIndex = self.destinations.count;
    Waypoint *newDestination = [[Waypoint alloc] initWithType:WaypointTypeDestination coordinate:coordinate leg:legIndex];
    
    [self.mutableDestinations addObject:newDestination];
    
    _routeRequiresRefresh = YES;
    
    return newDestination;
}

- (Waypoint *)addDestinationAtIndex:(NSInteger)index withCoordinate:(CLLocationCoordinate2D)coordinate {
    
    Waypoint *waypoint = [[Waypoint alloc] initWithType:WaypointTypeDestination coordinate:coordinate leg:index];
    [self.mutableDestinations insertObject:waypoint atIndex:index];
    
    _routeRequiresRefresh = YES;
    return waypoint;
}

- (void)removeDestination:(Waypoint *)destination {
    [self.mutableDestinations removeObject:destination];
    
    _routeRequiresRefresh = YES;
}

- (void)replaceDestinationAtIndex:(NSInteger)index withDestination:(Waypoint *)destination {
    
    [self.mutableDestinations replaceObjectAtIndex:index withObject:destination];
    
    _routeRequiresRefresh = YES;
}

- (void)updateDestination:(Waypoint *)waypoint toCoordinate:(CLLocationCoordinate2D)coordinate {
    
    if ([self.destinations containsObject:waypoint]) {
        NSInteger index = [self.destinations indexOfObject:waypoint];
        Waypoint *newDestionation = [[Waypoint alloc] initWithType:WaypointTypeDestination coordinate:coordinate];
        [self.mutableDestinations replaceObjectAtIndex:index withObject:newDestionation];
        
        _routeRequiresRefresh = YES;
    }
    else {
        NSLog(@"Not in the array!");
    }
}

- (NSArray *)turnsForLeg:(GoogleDirectionsLeg *)leg {
    NSMutableArray *turns = [NSMutableArray new];
    NSInteger legIndex = [self.route.legs indexOfObject:leg];
    
    for (GoogleDirectionsStep *step in leg.steps) {
        
        CLLocationCoordinate2D turnCoordinate = step.startLocation.coordinate;
        Waypoint *turnWaypoint = [[Waypoint alloc] initWithType:WaypointTypeTurn coordinate:turnCoordinate leg:legIndex];
        
        [turns addObject:turnWaypoint];
    }
    
    return [NSArray arrayWithArray:turns];
}

- (NSArray *)allWaypoints {
    
    NSMutableArray *allWaypoints = [NSMutableArray new];
    
    for (GoogleDirectionsLeg *leg in self.route.legs) {
        
        NSUInteger index = [self.route.legs indexOfObject:leg];
        Waypoint *startWaypoint = [self.destinations objectAtIndex:index];
        [allWaypoints addObject:startWaypoint];
        
        NSArray *turns = [self turnsForLeg:leg];
        [allWaypoints addObjectsFromArray:turns];
    }
    
    if (self.destinations.count > 0) {
        [allWaypoints addObject:self.destinations.lastObject];
    }
    
    return [NSArray arrayWithArray:allWaypoints];
}

- (NSMutableArray *)mutableDestinations {
    if (!_mutableDestinations) {
        _mutableDestinations = [NSMutableArray new];
    }
    return _mutableDestinations;
}

- (NSArray *)destinations {
    return [NSArray arrayWithArray:self.mutableDestinations];
}

@end
