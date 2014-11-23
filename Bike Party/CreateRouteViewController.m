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
#import "Ride.h"

@interface CreateRouteViewController ()

@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) EditRouteMapViewController *map;

@property (nonatomic) NSInteger editingIndex;

@property (strong, nonatomic) Ride *ride;

@end

@implementation CreateRouteViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.ride = [Ride new];
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

- (void)editRouteMap:(EditRouteMapViewController *)editRouteMap didBeginEditingWaypoint:(Waypoint *)waypoint {
    NSLog(@"Begin editing!");
    
    self.editingIndex = [self.ride.waypoints indexOfObject:waypoint];
    [self refreshNavBar];
}

- (void)editRouteMap:(EditRouteMapViewController *)editRouteMap didUpdateEditingWaypoint:(Waypoint *)waypoint {
    
    Waypoint *editingWaypoint = [self.ride.waypoints objectAtIndex:self.editingIndex];
    editingWaypoint.coordinate = waypoint.coordinate;
    
    //[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshRoute) object:nil];
    //[self performSelector:@selector(refreshRoute) withObject:nil afterDelay:1];
    
}

/*
- (void)editRouteMap:(EditRouteMapViewController *)editRouteMap didSelectPolyline:(id<NSCopying>)polylineIdentifier atCoordinate:(CLLocationCoordinate2D)coordinate {
    NSLog(@"selected polyline: %@", polylineIdentifier);
    
    NSNumber *identifier = (NSNumber *)polylineIdentifier;
    NSInteger index = identifier.integerValue + 1;
    
    Waypoint *waypoint = [[Waypoint alloc] initWithType:WaypointTypeViaPoint coordinate:coordinate];
    [self.map insertWaypoint:waypoint atIndex:index];
    [self.map beginEditingWaypoint:waypoint];
}
 */

- (void)editRouteMap:(EditRouteMapViewController *)editRouteMap didSelectCoordinate:(CLLocationCoordinate2D)coordinate {
    
    Waypoint *waypoint = [self.ride addDestinationWithCoordinate:coordinate];
    [self.map addWaypoint:waypoint];
    [self.map beginEditingWaypoint:waypoint];
}

- (void)editRouteMap:(EditRouteMapViewController *)editRouteMap didSelectWaypoint:(Waypoint *)waypoint {
    NSLog(@"waypoint selected");
    
    NSMutableArray *items = [NSMutableArray new];
    
    if (waypoint.type == WaypointTypeDestination) {
        UIBarButtonItem *trashButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(userDidTapDeleteWaypoint:)];
        [items addObject:trashButton];
    }
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [items addObject:flexibleSpace];
    
    if (waypoint.type == WaypointTypeDestination) {
        UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(userDidTapEditWaypoint:)];
        [items addObject:editButton];
    }
    
    [self.toolbar setItems:items animated:YES];
}

- (void)editRouteMap:(EditRouteMapViewController *)editRouteMap didDeselectWaypoint:(Waypoint *)waypoint {
    NSLog(@"Waypoint deselected");
    
    [self.toolbar setItems:@[] animated:YES];
}

- (void)userDidTapDone:(UIBarButtonItem *)button {
    
    NSLog(@"confirm edits");
    
    [self.ride replaceDestinationAtIndex:self.editingIndex withDestination:self.map.editingWaypoint];
    
    [self.map confirmEdits];
    [self refreshNavBar];
    [self refreshRoute];
}

- (void)userDidTapCancel:(UIBarButtonItem *)button {
    
    [self.ride removeDestination:self.map.editingWaypoint];
    [self.map cancelEdits];
    
    [self refreshNavBar];
    [self refreshRoute];
}

- (void)userDidTapDeleteWaypoint:(UIBarButtonItem *)button {
    NSLog(@"delete");
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete?" message:@"Are you sure you would like to delete this waypoint?" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        
        [self.ride removeDestination:self.map.selectedWaypoint];
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
    
    Waypoint *waypoint = self.map.selectedWaypoint;
    if (waypoint.type == WaypointTypeDestination) {
        [self.map beginEditingWaypoint:waypoint];
    }
    else if (waypoint.type == WaypointTypeTurn) {
        
        /*
        NSInteger totalSteps = 0;
        for (GoogleDirectionsLeg *leg in self.route.legs) {
            for (GoogleDirectionsStep *step in leg.steps) {
                
                totalSteps += leg.steps.count;
                BOOL foundWaypoint = NO;
                CLLocationCoordinate2D stepCoordinate = step.startLocation.coordinate;
                CLLocationCoordinate2D waypointCoordinate = waypoint.coordinate;
                if (stepCoordinate.latitude == waypointCoordinate.latitude && stepCoordinate.longitude == waypointCoordinate.longitude) {
                    foundWaypoint = YES;
                    break;
                }
                
                if (foundWaypoint) {
                    break;
                }
            }
        }
        
        Waypoint *newWaypoint = [[Waypoint alloc] initWithType:WaypointTypeDestination coordinate:waypoint.coordinate];
        [self.map insertWaypoint:newWaypoint atIndex:totalSteps];
        [self.map beginEditingWaypoint:newWaypoint];
         */
    }
}

- (void)refreshRoute {
    
    if (self.ride.waypoints.count > 1) {
        
        if (!self.ride.route) {
            
            [self.ride loadDirectionsWithCallback:^(GoogleDirectionsRoute *route, NSError *error) {
                if (!error) {
                    [self performSelectorOnMainThread:@selector(drawRoute) withObject:nil waitUntilDone:NO];
                }
                else {
                    NSLog(@"Error loading route.");
                }
            }];
        }
        else {
            [self drawRoute];
        }
    }
    
}

- (void)drawRoute {
    
    [self.map removeAllPolylines];
    [self.map removeAllWaypoints];
    
    [self.map addPolyline:self.ride.route.overviewPolyline withIdentifier:@"polyline"];
    [self.map addWaypoints:self.ride.allWaypoints];
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
