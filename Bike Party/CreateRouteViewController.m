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
#import "GoogleDirectionsStep.h"

@interface CreateRouteViewController ()

@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) EditRouteMapViewController *map;

@property (strong, nonatomic) GoogleDirectionsRoute *route;

@end

@implementation CreateRouteViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //[self performSelector:@selector(testicle) withObject:nil afterDelay:5];
}

/*
- (void)testicle {
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(37.7833, 122.4167);
    Waypoint *waypoint = [[Waypoint alloc] initWithCoordinate:coordinate andName:@"Testicle"];
    [self.editRouteMap addWaypoint:waypoint];
}
 */

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[EditRouteMapViewController class]]) {
        EditRouteMapViewController *editRouteMap = (EditRouteMapViewController *)segue.destinationViewController;
        editRouteMap.delegate = self;
        self.map = editRouteMap;
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
    
    Waypoint *waypoint = [[Waypoint alloc] initWithType:WaypointTypeViaPoint coordinate:coordinate];
    [self.map insertWaypoint:waypoint atIndex:index];
    [self.map beginEditingWaypoint:waypoint];
}

- (void)editRouteMap:(EditRouteMapViewController *)editRouteMap didUpdateEditingWaypoint:(Waypoint *)waypoint {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshRoute) object:nil];
    [self performSelector:@selector(refreshRoute) withObject:nil afterDelay:1];
    
}

- (void)editRouteMap:(EditRouteMapViewController *)editRouteMap didSelectCoordinate:(CLLocationCoordinate2D)coordinate {
    
    Waypoint *waypoint = [[Waypoint alloc] initWithType:WaypointTypeDestination coordinate:coordinate title:nil];
    [self.map addWaypoint:waypoint];
    [self.map beginEditingWaypoint:waypoint];
}

- (void)editRouteMap:(EditRouteMapViewController *)editRouteMap didSelectWaypoint:(Waypoint *)waypoint {
    NSLog(@"waypoint selected");
    
    UIBarButtonItem *trashButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(userDidTapDeleteWaypoint:)];
    
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(userDidTapEditWaypoint:)];
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    NSArray *items = @[trashButton, flexibleSpace, editButton];
    [self.toolbar setItems:items animated:YES];
}

- (void)editRouteMap:(EditRouteMapViewController *)editRouteMap didDeselectWaypoint:(Waypoint *)waypoint {
    NSLog(@"Waypoint deselected");
    
    [self.toolbar setItems:@[] animated:YES];
}

- (void)userDidTapDone:(UIBarButtonItem *)button {
    [self.map confirmEdits];
    [self refreshNavBar];
    [self refreshRoute];
}

- (void)userDidTapCancel:(UIBarButtonItem *)button {
    [self.map cancelEdits];
    [self refreshNavBar];
    [self refreshRoute];
}

- (void)userDidTapDeleteWaypoint:(UIBarButtonItem *)button {
    NSLog(@"delete");
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete?" message:@"Are you sure you would like to delete this waypoint?" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self.map removeWaypoint:self.map.selectedWaypoint];
        [self refreshRoute];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:confirm];
    [alert addAction:cancel];
    [self showViewController:alert sender:self];
}

- (void)userDidTapEditWaypoint:(UIBarButtonItem *)button {
    NSLog(@"Edit");
    
    if (self.map.selectedWaypoint.type == WaypointTypeDestination) {
        [self.map beginEditingWaypoint:self.map.selectedWaypoint];
    }
}

- (void)refreshRoute {
    
    if (self.map.waypoints.count > 1) {
        
        NSMutableArray *locations = [NSMutableArray new];
        for (Waypoint *waypoint in self.map.waypoints) {
            
            if (waypoint.type == WaypointTypeDestination) {
                CLLocationCoordinate2D coordinate = waypoint.coordinate;
                CLLocation *location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
                [locations addObject:location];
            }
        }
        
        GoogleDirectionsRequest *directions = [[GoogleDirectionsRequest alloc] initWithAPIKey:@"AIzaSyBHeXy9Im_mAQyCqugF8_kBdKnerpQ0kjE"];
        [directions loadDirectionsForPath:locations WithCallback:^(NSArray *routes, NSError *error) {
            
            if (!error) {
                
                GoogleDirectionsRoute *route = routes.firstObject;
                
                if (route.legs.count < self.route.legs.count) {
                    for (NSUInteger i = route.legs.count; i < self.route.legs.count; i++) {
                        NSNumber *polylineIdentifier = [NSNumber numberWithUnsignedInteger:i];
                        [self.map removePolylineWithIdentifier:polylineIdentifier];
                    }
                }
                
                self.route = route;
                
                [self performSelectorOnMainThread:@selector(drawRoute) withObject:nil waitUntilDone:NO];
            }
        }];
    }
    else {
        [self.map removePolylineWithIdentifier:[NSNumber numberWithInt:0]];
    }
    
}

- (void)drawRoute {
    
    int count = 0;
    for (GoogleDirectionsLeg *leg in self.route.legs) {
        
        NSNumber *identifier = [NSNumber numberWithInt:count];
        [self.map addPolyline:leg.polyline withIdentifier:identifier];
        
        count++;
        
        for (GoogleDirectionsStep *step in leg.steps) {
            CLLocationCoordinate2D turnCoordinate = step.startLocation.coordinate;
            
            if (step != leg.steps.firstObject) {
                Waypoint *turnWaypoint = [[Waypoint alloc] initWithType:WaypointTypeTurn coordinate:turnCoordinate];
                [self.map addWaypoint:turnWaypoint];
            }
        }
    }
}

- (void)refreshNavBar {
    
    UIBarButtonItem *leftButton;
    UIBarButtonItem *rightButton;
    
    if (self.map.state == EditRouteMapViewControllerStateIdle) {
        
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
