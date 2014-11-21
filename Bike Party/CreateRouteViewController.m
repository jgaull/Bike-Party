//
//  CreateRouteViewController.m
//  Bike Party
//
//  Created by Jon on 11/20/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import "CreateRouteViewController.h"
#import "GoogleDirectionsRequest.h"
#import "GoogleDirectionsLeg.h"

@interface CreateRouteViewController ()

@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) EditRouteMapViewController *editRouteMap;

@property (strong, nonatomic) GoogleDirectionsRoute *route;

@end

@implementation CreateRouteViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[EditRouteMapViewController class]]) {
        EditRouteMapViewController *editRouteMap = (EditRouteMapViewController *)segue.destinationViewController;
        editRouteMap.delegate = self;
        self.editRouteMap = editRouteMap;
    }
}

- (void)editRouteMap:(EditRouteMapViewController *)editRouteMap didBeginEditingWaypoint:(CLLocation *)waypoint {
    NSLog(@"Begin editing!");
    [self refreshNavBar];
}

- (void)editRouteMap:(EditRouteMapViewController *)editRouteMap didSelectPolyline:(id<NSCopying>)polylineIdentifier atCoordinate:(CLLocationCoordinate2D)coordinate {
    NSLog(@"selected polyline: %@", polylineIdentifier);
    
    NSNumber *identifier = (NSNumber *)polylineIdentifier;
    NSInteger index = identifier.integerValue + 1;
    
    Waypoint *waypoint = [[Waypoint alloc] initWithCoordinate:coordinate];
    [self.editRouteMap insertWaypoint:waypoint atIndex:index];
}

- (void)editRouteMap:(EditRouteMapViewController *)editRouteMap didUpdateEditingWaypoint:(Waypoint *)waypoint {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshRoute) object:nil];
    [self performSelector:@selector(refreshRoute) withObject:nil afterDelay:1];
    
}

- (void)userDidTapDone:(UIBarButtonItem *)button {
    [self.editRouteMap confirmEdits];
    [self refreshNavBar];
    [self refreshRoute];
}

- (void)userDidTapCancel:(UIBarButtonItem *)button {
    [self.editRouteMap cancelEdits];
    [self refreshNavBar];
    [self refreshRoute];
}

- (void)refreshRoute {
    
    if (self.editRouteMap.waypoints.count > 1) {
        
        NSMutableArray *locations = [NSMutableArray new];
        for (Waypoint *waypoint in self.editRouteMap.waypoints) {
            CLLocationCoordinate2D coordinate = waypoint.coordinate;
            CLLocation *location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
            [locations addObject:location];
        }
        
        GoogleDirectionsRequest *directions = [[GoogleDirectionsRequest alloc] initWithAPIKey:@"AIzaSyBHeXy9Im_mAQyCqugF8_kBdKnerpQ0kjE"];
        [directions loadDirectionsForPath:locations WithCallback:^(NSArray *routes, NSError *error) {
            if (!error) {
                self.route = routes.firstObject;
                [self performSelectorOnMainThread:@selector(drawRoute) withObject:nil waitUntilDone:NO];
            }
        }];
    }
    else {
        [self.editRouteMap removePolylineWithIdentifier:[NSNumber numberWithInt:0]];
    }
    
}

- (void)drawRoute {
    
    int count = 0;
    for (GoogleDirectionsLeg *leg in self.route.legs) {
        
        NSNumber *identifier = [NSNumber numberWithInt:count];
        [self.editRouteMap addPolyline:leg.polyline withIdentifier:identifier];
        
        count++;
    }
}

- (void)refreshNavBar {
    
    UIBarButtonItem *leftButton;
    UIBarButtonItem *rightButton;
    
    if (self.editRouteMap.state == EditRouteMapViewControllerStateIdle) {
        
        leftButton = nil;
        rightButton = nil;
    }
    else {
        leftButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(userDidTapCancel:)];
        rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(userDidTapDone:)];
    }
    
    [self.navigationBar.topItem setLeftBarButtonItem:leftButton animated:YES];
    [self.navigationBar.topItem setRightBarButtonItem:rightButton animated:YES];
}

@end
