//
//  Ride.m
//  Bike Party
//
//  Created by Jon on 11/23/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import "Ride.h"
#import "TurnAnnotation.h"
#import "GoogleDirectionsRoute.h"

@interface Ride ()

@property (strong, nonatomic) NSArray *routes;

@end

@implementation Ride

/*
- (id)initWithRoute:(GoogleDirectionsRoute *)route {
    self = [super init];
    if (self) {
        self.route = route;
        _overviewPolyline = self.route.overviewPolyline;
    }
    return self;
}
 */

- (id)initWithRoutes:(NSArray *)routes {
    self = [super init];
    if (self) {
        //need to parse some stuff!
        self.routes = routes;
    }
    return self;
}

- (NSArray *)turnAnnotations {
    NSMutableArray *turns = [NSMutableArray new];
    
    NSInteger legCount = 0;
    
    for (GoogleDirectionsRoute *route in self.routes) {
        for (GoogleDirectionsLeg *leg in route.legs) {
            for (GoogleDirectionsStep *step in leg.steps) {
                
                CLLocationCoordinate2D turnCoordinate = step.startLocation.coordinate;
                TurnAnnotation *turnAnnotation = [[TurnAnnotation alloc] initWithCoordinate:turnCoordinate leg:legCount];
                [turns addObject:turnAnnotation];
            }
            legCount++;
        }
    }
    
    return [NSArray arrayWithArray:turns];
}

- (MKPolyline *)overviewPolyline {
    
    int totalPoints = 0;
    
    for (GoogleDirectionsRoute *route in self.routes) {
        totalPoints += route.overviewPolyline.pointCount;
    }
    
    MKMapPoint points[totalPoints];
    int currentIndex = 0;
    for (GoogleDirectionsRoute *route in self.routes) {
        for (int i = 0; i < route.overviewPolyline.pointCount; i++) {
            points[currentIndex] = route.overviewPolyline.points[i];
            currentIndex++;
        }
    }
    
    return [MKPolyline polylineWithPoints:points count:totalPoints];
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

@end
