//
//  RouteLeg.m
//  Bike Party
//
//  Created by Jon on 11/14/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#define API_KEY @"AIzaSyBHeXy9Im_mAQyCqugF8_kBdKnerpQ0kjE"

#import "RouteLeg.h"
#import "GoogleDirectionsRequest.h"

@interface RouteLeg ()

//Get rid of this shit.
@property (readonly, nonatomic) NSArray *locations;

@end

@implementation RouteLeg

- (CLLocation *)findWaypointWithCoordinate:(CLLocationCoordinate2D)waypointCoordinate {
    
    for (CLLocation *location in self.locations) {
        if (location.coordinate.latitude == waypointCoordinate.latitude &&
            location.coordinate.longitude == waypointCoordinate.longitude) {
            return location;
        }
    }
    
    return nil;
}

- (void)loadDirectionsWithCallback:(void (^)(GoogleDirectionsRoute *, NSError *))callback {
    GoogleDirectionsRequest *directionsRequest = [[GoogleDirectionsRequest alloc] initWithAPIKey:API_KEY];
    
    [directionsRequest loadDirectionsForPath:self.locations WithCallback:^(NSArray *routes, NSError *error) {
        if (error) {
            callback(nil, error);
        }
        else {
            callback(routes.firstObject, error);
        }
    }];
}

- (NSMutableArray *)waypoints {
    if (!_waypoints) {
        _waypoints = [NSMutableArray new];
    }
    return _waypoints;
}

//Get rid of this shit.
- (NSArray *)locations {
    NSMutableArray *locations = [NSMutableArray new];
    [locations addObject:self.startPlace.location];
    [locations addObjectsFromArray:self.waypoints];
    [locations addObject:self.endPlace.location];
    return [NSArray arrayWithArray:locations];
}

@end
