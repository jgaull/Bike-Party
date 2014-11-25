//
//  Ride.m
//  Bike Party
//
//  Created by Jon on 11/23/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import "Ride.h"
#import "TurnAnnotation.h"

@interface Ride ()

@property (strong, nonatomic) NSMutableArray *mutableWaypoints;

@end

@implementation Ride

- (void)loadDirectionsWithCallback:(void (^)(GoogleDirectionsRoute *, NSError *))callback {
    
    if (self.routeRequiresRefresh) {
        
        NSMutableArray *path = [NSMutableArray new];
        for (Waypoint *waypoint in self.waypoints) {
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
    
    Waypoint *newDestination = [[Waypoint alloc] initWithType:WaypointTypeDestination coordinate:coordinate];
    
    [self.mutableWaypoints addObject:newDestination];
    
    _routeRequiresRefresh = YES;
    
    return newDestination;
}

- (Waypoint *)addViaPointInLeg:(NSInteger)leg withCoordinate:(CLLocationCoordinate2D)coordinate {
    
    Waypoint *waypoint = [[Waypoint alloc] initWithType:WaypointTypeViaPoint coordinate:coordinate];
    [self.mutableWaypoints insertObject:waypoint atIndex:leg + 1];
    
    _routeRequiresRefresh = YES;
    return waypoint;
}

- (void)removeDestination:(Waypoint *)destination {
    [self.mutableWaypoints removeObject:destination];
    
    _routeRequiresRefresh = YES;
}

- (void)replaceDestinationAtIndex:(NSInteger)index withDestination:(Waypoint *)destination {
    
    [self.mutableWaypoints replaceObjectAtIndex:index withObject:destination];
    
    _routeRequiresRefresh = YES;
}

- (void)updateDestination:(Waypoint *)waypoint toCoordinate:(CLLocationCoordinate2D)coordinate {
    
    if ([self.waypoints containsObject:waypoint]) {
        NSInteger index = [self.waypoints indexOfObject:waypoint];
        Waypoint *newDestionation = [[Waypoint alloc] initWithType:WaypointTypeDestination coordinate:coordinate];
        [self.mutableWaypoints replaceObjectAtIndex:index withObject:newDestionation];
        
        _routeRequiresRefresh = YES;
    }
    else {
        NSLog(@"Not in the array!");
    }
}

- (NSArray *)turnAnnotations {
    NSMutableArray *turns = [NSMutableArray new];
    
    for (int i = 0; i < self.route.legs.count; i++) {
        
        GoogleDirectionsLeg *leg = [self.route.legs objectAtIndex:i];
        
        for (GoogleDirectionsStep *step in leg.steps) {
            
            CLLocationCoordinate2D turnCoordinate = step.startLocation.coordinate;
            TurnAnnotation *turnAnnotation = [[TurnAnnotation alloc] initWithCoordinate:turnCoordinate leg:i];
            [turns addObject:turnAnnotation];
        }
    }
    
    return [NSArray arrayWithArray:turns];
}

/*
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
 */

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
