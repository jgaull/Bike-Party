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
@property (weak, nonatomic) IBOutlet EditRouteMapViewController *mapView;

@property (strong, nonatomic) UITapGestureRecognizer *tap;

@property (strong, nonatomic) Waypoint *selectedWaypoint;
@property (nonatomic) NSInteger editingIndex;
@property (nonatomic) BOOL transitioningToEditMode;
@property (nonatomic) BOOL isEditing;
@property (strong, nonatomic) MKAnnotationView *pinView;

@property (strong, nonatomic) Ride *ride;

@end

@implementation CreateRouteViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.ride = [Ride new];
    //[self performSelector:@selector(testicle) withObject:nil afterDelay:5];
    
    self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    self.tap.delegate = self;
    [self.mapView addGestureRecognizer:self.tap];
}

/*
- (void)insertWaypoint:(Waypoint *)waypoint atIndex:(NSUInteger)index {
    [self.mutableWaypoints insertObject:waypoint atIndex:index];
    [self.mapView addAnnotation:waypoint];
}
 */

- (void)confirmEdits {
    
    [self.ride addDestinationWithCoordinate:self.mapView.centerCoordinate];
    [self.mapView addAnnotation:self.selectedWaypoint];
    [self endEditing];
}

- (void)cancelEdits {
    [self.ride removeDestination:self.selectedWaypoint];
    [self endEditing];
}

- (void)beginEditingWaypoint:(Waypoint *)waypoint {
    
    //When the pin and map are centered we use this
    self.selectedWaypoint = waypoint;
    self.transitioningToEditMode = YES;
    self.isEditing = YES;
    self.tap.enabled = NO;
    
    self.mapView.lockCenterWhileZooming = YES;
    
    CLLocationCoordinate2D coordinate = waypoint.coordinate;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinate, 0.005131, 0.004123);
    [self.mapView setRegion:region animated:YES];
    
    [self refreshNavBar];
}

- (void)endEditing {
    
    [self.mapView deselectAnnotation:self.selectedWaypoint animated:YES];
    
    self.selectedWaypoint = nil;
    self.isEditing = NO;
    self.tap.enabled = YES;
    
    self.mapView.lockCenterWhileZooming = NO;
    
    [self.pinView removeFromSuperview];
    self.pinView = nil;
    
    [self refreshNavBar];
}

- (void)handleTap:(UITapGestureRecognizer *)tap {
    if (tap.state == UIGestureRecognizerStateEnded && !self.selectedWaypoint) {
        
        CGPoint tapPoint = [tap locationInView:self.mapView];
        CLLocationCoordinate2D tapCoordinate = [self.mapView convertPoint:tapPoint toCoordinateFromView:self.mapView];
        Waypoint *tapWaypoint = [[Waypoint alloc] initWithType:WaypointTypeDestination coordinate:tapCoordinate];
        [self.mapView addAnnotation:tapWaypoint];
        [self beginEditingWaypoint:tapWaypoint];
    }
}

/*
- (void)testicle {
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(37.7833, 122.4167);
    Waypoint *waypoint = [[Waypoint alloc] initWithCoordinate:coordinate andName:@"Testicle"];
    [self.editRouteMap addWaypoint:waypoint];
}
 */

/*
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[EditRouteMapViewController class]]) {
        EditRouteMapViewController *editRouteMap = (EditRouteMapViewController *)segue.destinationViewController;
        editRouteMap.delegate = self;
        self.map = editRouteMap;
    }
}
 */

/*
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
 */

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

/*
- (void)editRouteMap:(EditRouteMapViewController *)editRouteMap didSelectCoordinate:(CLLocationCoordinate2D)coordinate {
    
    Waypoint *waypoint = [self.ride addDestinationWithCoordinate:coordinate];
    [self.map addWaypoint:waypoint];
    [self.map beginEditingWaypoint:waypoint];
}
 */

/*
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
 */

- (void)userDidTapDone:(UIBarButtonItem *)button {
    
    NSLog(@"confirm edits");
    
    [self confirmEdits];
    [self refreshNavBar];
    [self refreshRoute];
}

- (void)userDidTapCancel:(UIBarButtonItem *)button {
    
    [self.ride removeDestination:self.selectedWaypoint];
    [self cancelEdits];
    
    [self refreshNavBar];
    [self refreshRoute];
}

- (void)userDidTapDeleteWaypoint:(UIBarButtonItem *)button {
    NSLog(@"delete");
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete?" message:@"Are you sure you would like to delete this waypoint?" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        
        [self.ride removeDestination:self.selectedWaypoint];
        
        [self endEditing];
        [self refreshRoute];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:confirm];
    [alert addAction:cancel];
    [self showViewController:alert sender:self];
}

- (void)userDidTapEditWaypoint:(UIBarButtonItem *)button {
    NSLog(@"Edit");
    
    Waypoint *waypoint = self.selectedWaypoint;
    if (waypoint.type == WaypointTypeDestination) {
        [self beginEditingWaypoint:waypoint];
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

#pragma mark - UIGestureRecognizerDelegate Methods
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:[MKAnnotationView class]]) {
        return NO;
    }
    return YES;
}

#pragma mark - MKMapViewDelegate Methods
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    
    if ([annotation isKindOfClass:[Waypoint class]]) {
        Waypoint *waypoint = (Waypoint *)annotation;
        
        NSString *identifier = [self annotationIdentifierForWaypoint:waypoint];
        MKAnnotationView *annotationView = [self.mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        
        if (!annotationView) {
            
            if (waypoint.type == WaypointTypeDestination) {
                annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier: identifier];
                UIImage *pinImage = [UIImage imageNamed:@"destinationMarker.png"];
                annotationView.image = pinImage;
                annotationView.centerOffset = CGPointMake(0, -pinImage.size.height / 2);
            }
            else if (waypoint.type == WaypointTypeTurn) {
                annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
                UIImage *pinImage = [UIImage imageNamed:@"turnMarker.png"];
                annotationView.image = pinImage;
                annotationView.centerOffset = CGPointZero;
            }
        }
        
        annotationView.annotation = waypoint;
        
        return annotationView;
    }
    
    return nil;
}

- (NSString *)annotationIdentifierForWaypoint:(Waypoint *)waypoint {
    NSString *identifier;
    switch (waypoint.type) {
        case WaypointTypeDestination:
            identifier = @"destination";
            break;
        case WaypointTypeTurn:
            identifier = @"turn";
            break;
        case WaypointTypeViaPoint:
            identifier = @"via";
            break;
            
        default:
            identifier = @"";
            NSLog(@"unknown waypoint type");
            break;
    }
    
    return identifier;
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    if (self.transitioningToEditMode) {
        
        MKAnnotationView *mapPin = [self.mapView viewForAnnotation:self.selectedWaypoint];
        
        [self.mapView removeAnnotation:self.selectedWaypoint];
        
        CGSize pinSize = mapPin.frame.size;
        CGSize frameSize = self.mapView.frame.size;
        CGPoint offset = mapPin.centerOffset;
        
        mapPin.frame = CGRectMake(frameSize.width / 2 - pinSize.width / 2 + offset.x, frameSize.height / 2 - pinSize.height / 2 + offset.y, pinSize.width, pinSize.height);
        [self.mapView addSubview:mapPin];
        
        self.pinView = [self mapView:mapView viewForAnnotation:self.selectedWaypoint];
        
        self.transitioningToEditMode = NO;
    }
    else if (self.isEditing) {
        self.selectedWaypoint.coordinate = self.mapView.centerCoordinate;
    }
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    
    MKPolylineRenderer *polylineRenderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
    polylineRenderer.strokeColor = [UIColor colorWithRed:0.9843137255 green:0.4470588235 blue:0.1450980392 alpha:1];
    polylineRenderer.lineWidth = 4.0;
    
    return polylineRenderer;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    NSLog(@"Selected");
    
    if ([view.annotation isKindOfClass:[Waypoint class]]) {
        Waypoint *waypoint = (Waypoint *)view.annotation;
        self.selectedWaypoint = waypoint;
        [self refreshNavBar];
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    NSLog(@"Deselected");
    self.selectedWaypoint = nil;
    [self refreshNavBar];
}

- (void)refreshRoute {
    
    if (self.ride.waypoints.count > 1) {
        
        if (self.ride.routeRequiresRefresh) {
            
            [self.mapView removeAnnotations:self.ride.allWaypoints];
            [self.mapView removeOverlay:self.ride.route.overviewPolyline];
            
            [self.ride loadDirectionsWithCallback:^(GoogleDirectionsRoute *route, NSError *error) {
                if (!error) {
                    
                    //If this is called on a background thread the app crashes.
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
    
    [self.mapView addAnnotations:self.ride.allWaypoints];
    [self.mapView addOverlay:self.ride.route.overviewPolyline];
}

- (void)refreshNavBar {
    
    UIBarButtonItem *leftButton;
    UIBarButtonItem *rightButton;
    
    if (self.isEditing) {
        
        leftButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(userDidTapCancel:)];
        rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(userDidTapDone:)];
    }
    else if (self.selectedWaypoint) {
        
            rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(userDidTapEditWaypoint:)];
    }
    
    [self.navigationBar.topItem setLeftBarButtonItem:leftButton animated:YES];
    [self.navigationBar.topItem setRightBarButtonItem:rightButton animated:YES];
}

#pragma mark - Getters and Setters

@end
