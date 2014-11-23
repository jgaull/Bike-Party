//
//  RideLeg.m
//  Bike Party
//
//  Created by Jon on 11/23/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import "RideLeg.h"

@interface RideLeg ()

@property (strong, nonatomic) NSMutableArray *mutableWaypoints;

@end

@implementation RideLeg

- (id)initWithStartWaypoint:(Waypoint *)startWaypoint {
    self = [super self];
    if (self) {
        [self.mutableWaypoints addObject:startWaypoint];
    }
    return self;
}

- (id)initWithStartWaypoint:(Waypoint *)startWaypoint andEndWaypoint:(Waypoint *)endWaypoint {
    self = [super self];
    if (self) {
        [self.mutableWaypoints addObject:startWaypoint];
        [self.mutableWaypoints addObject:endWaypoint];
    }
    return self;
}

- (void)loadDirectionsWithCallback:(void (^)(GoogleDirectionsRoute *, NSError *))callback {
    if (!self.route) {
        
        NSMutableArray *path = [NSMutableArray new];
        for (Waypoint *waypoint in self.waypoints) {
            CLLocation *location = [[CLLocation alloc] initWithLatitude:waypoint.coordinate.latitude longitude:waypoint.coordinate.longitude];
            [path addObject:location];
        }
        
        GoogleDirectionsRequest *directionsRequest = [[GoogleDirectionsRequest alloc] initWithAPIKey:@"AIzaSyBHeXy9Im_mAQyCqugF8_kBdKnerpQ0kjE"];
        
        [directionsRequest loadDirectionsForPath:path WithCallback:^(NSArray *routes, NSError *error) {
            if (!error) {
                _route = routes.firstObject;
            }
            
            callback(_route, error);
        }];
    }
    else {
        callback(_route, nil);
    }
}

- (Waypoint *)startDestination {
    return self.waypoints.firstObject;
}

- (Waypoint *)endDestination {
    return self.waypoints.lastObject;
}

- (NSArray *)waypoints {
    return [NSArray arrayWithArray:self.mutableWaypoints];
}

- (NSMutableArray *)mutableWaypoints {
    if (!_mutableWaypoints) {
        _mutableWaypoints = [NSMutableArray new];
    }
    return _mutableWaypoints;
}

@end
