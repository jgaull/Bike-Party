//
//  RouteLoader.m
//  Bike Party
//
//  Created by Jon on 11/27/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#define MAX_WAYPOINTS 10

#import "RouteLoader.h"
#import "Waypoint.h"
#import "GoogleDirectionsRequest.h"
#import "GoogleDirectionsRoute.h"

@interface RouteLoader ()

@property (strong, nonatomic) NSMutableArray *loadedDirections;
@property (strong, nonatomic) NSArray *waypoints;
@property (strong, nonatomic) Callback callback;

@end

@implementation RouteLoader

- (void)loadDirectionsForWaypoints:(NSArray *)waypoints withCallback:(Callback)callback {
    
    self.waypoints = waypoints;
    self.callback = callback;
    
    NSMutableArray *path = [NSMutableArray new];
    for (Waypoint *waypoint in waypoints) {
        CLLocation *location = [[CLLocation alloc] initWithLatitude:waypoint.coordinate.latitude longitude:waypoint.coordinate.longitude];
        [path addObject:location];
    }
    
    NSMutableArray *paths = [NSMutableArray new];
    
    int i = 0;
    while (i < path.count) {
        
        NSInteger length = MIN(path.count - i, MAX_WAYPOINTS);
        
        if (path.count - i - length == 1) {
            length--;
        }
        
        NSRange range = NSMakeRange(i, length);
        NSArray *pathSubsection = [path subarrayWithRange:range];
        [paths addObject:pathSubsection];
        
        i += length;
    }
    
    for (int i = 0; i < paths.count; i++) {
        NSArray *subPath = [paths objectAtIndex:i];
        [self performSelector:@selector(loadDirectionsForPath:) withObject:subPath afterDelay:i * 0.5];
    }
}

- (void)loadDirectionsForPath:(NSArray *)path {
    
    GoogleDirectionsRequest *directions = [[GoogleDirectionsRequest alloc] initWithAPIKey:@"AIzaSyBHeXy9Im_mAQyCqugF8_kBdKnerpQ0kjE"];
    [directions loadDirectionsForPath:path WithCallback:^(NSArray *routes, NSError *error) {
        if (!error) {
            //_route = routes.firstObject;
            
            GoogleDirectionsRoute *newRoute = routes.firstObject;
            [self.loadedDirections addObject:newRoute];
            
            NSInteger loadedWaypoints = 0;
            for (GoogleDirectionsRoute *route in self.loadedDirections) {
                loadedWaypoints += route.legs.count + 1;
            }
            
            if (loadedWaypoints >= self.waypoints.count) {
                self.callback(self.loadedDirections, nil);
            }
        }
        else {
            self.callback(nil, error);
        }
    }];
}

- (NSMutableArray *)loadedDirections {
    if (!_loadedDirections) {
        _loadedDirections = [NSMutableArray new];
    }
    return _loadedDirections;
}

@end
