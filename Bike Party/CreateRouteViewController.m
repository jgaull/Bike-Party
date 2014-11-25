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
@property (weak, nonatomic) IBOutlet CenterLockingMapView *mapView;

@property (strong, nonatomic) UITapGestureRecognizer *tap;

@property (strong, nonatomic) Waypoint *editingWaypoint;
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

#pragma mark - Gesture Recognizer Handlers
- (void)handleTap:(UITapGestureRecognizer *)tap {
    if (tap.state == UIGestureRecognizerStateEnded && self.mapView.selectedAnnotations.count == 0) {
        
        CGPoint tapPoint = [tap locationInView:self.mapView];
        CLLocationCoordinate2D tapCoordinate = [self.mapView convertPoint:tapPoint toCoordinateFromView:self.mapView];
        Waypoint *tapWaypoint = [self.ride addDestinationWithCoordinate:tapCoordinate];
        
        [self.mapView addAnnotation:tapWaypoint];
        [self beginEditingWaypoint:tapWaypoint];
    }
}

#pragma mark - Button Callbacks
- (void)userDidTapDone:(UIBarButtonItem *)button {
    
    NSLog(@"confirm edits");
    
    if (self.editingWaypoint.type == WaypointTypeTurn) {
        [self.ride addDestinationAtIndex:self.editingWaypoint.leg + 1 withCoordinate:self.mapView.centerCoordinate];
    }
    else {
        [self.ride updateDestination:self.editingWaypoint toCoordinate:self.mapView.centerCoordinate];
    }
    
    [self.mapView addAnnotation:self.editingWaypoint];
    [self endEditing];
    
    [self refreshNavBar];
    [self refreshRoute];
}

- (void)userDidTapCancel:(UIBarButtonItem *)button {
    
    [self.mapView addAnnotation:self.editingWaypoint];
    [self.mapView setCenterCoordinate:self.editingWaypoint.coordinate animated:YES];
    [self endEditing];
    
    [self refreshNavBar];
    [self refreshRoute];
}

- (void)userDidTapDeleteWaypoint:(UIBarButtonItem *)button {
    NSLog(@"delete");
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete?" message:@"Are you sure you would like to delete this waypoint?" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        
        Waypoint *selectedWaypoint = self.mapView.selectedAnnotations.firstObject;
        [self.ride removeDestination:selectedWaypoint];
        
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
    
    Waypoint *waypoint = self.mapView.selectedAnnotations.firstObject;
    if (waypoint.type == WaypointTypeDestination) {
        
        [self beginEditingWaypoint:waypoint];
    }
    else if (waypoint.type == WaypointTypeTurn) {
        
        [self beginEditingWaypoint:waypoint];
    }
}

- (void)beginEditingWaypoint:(Waypoint *)waypoint {
    
    //When the pin and map are centered we use this
    self.editingWaypoint = waypoint;
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
    
    [self.mapView deselectAnnotation:self.editingWaypoint animated:YES];
    
    self.editingWaypoint = nil;
    self.isEditing = NO;
    self.tap.enabled = YES;
    
    self.mapView.lockCenterWhileZooming = NO;
    
    [self.pinView removeFromSuperview];
    self.pinView = nil;
    
    [self refreshNavBar];
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
        
        MKAnnotationView *mapPin = [self.mapView viewForAnnotation:self.editingWaypoint];
        
        [self.mapView removeAnnotation:self.editingWaypoint];
        
        CGSize pinSize = mapPin.frame.size;
        CGSize frameSize = self.mapView.frame.size;
        CGPoint offset = mapPin.centerOffset;
        
        mapPin.frame = CGRectMake(frameSize.width / 2 - pinSize.width / 2 + offset.x, frameSize.height / 2 - pinSize.height / 2 + offset.y, pinSize.width, pinSize.height);
        [self.mapView addSubview:mapPin];
        
        self.pinView = [self mapView:mapView viewForAnnotation:self.editingWaypoint];
        
        self.transitioningToEditMode = NO;
    }
    else if (self.isEditing) {
        //self.editingWaypoint.coordinate = self.mapView.centerCoordinate;
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
        [self refreshNavBar];
    }
    else {
        NSLog(@"Wrong type of annotation!");
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    NSLog(@"Deselected");
    [self refreshNavBar];
}

#pragma mark - UI Helpers
- (void)refreshRoute {
    
    [self clearRoute];
    
    [self.ride loadDirectionsWithCallback:^(GoogleDirectionsRoute *route, NSError *error) {
        if (!error) {
            
            //If this is called on a background thread the app crashes.
            //[self performSelectorOnMainThread:@selector(drawRoute) withObject:nil waitUntilDone:NO];
        }
        else {
            NSLog(@"Error loading route.");
        }
        
        [self performSelectorOnMainThread:@selector(drawRoute) withObject:nil waitUntilDone:NO];
    }];
    
}

- (void)clearRoute {
    
    NSArray *annotations = self.mapView.annotations;
    NSArray *overlays = self.mapView.overlays;
    [self.mapView removeAnnotations:annotations];
    [self.mapView removeOverlays:overlays];
}

- (void)drawRoute {
    
    if (self.ride.allWaypoints.count > 0) {
        [self.mapView addAnnotations:self.ride.allWaypoints];
    }
    
    if (self.ride.route.overviewPolyline) {
        [self.mapView addOverlay:self.ride.route.overviewPolyline];
    }
}

- (void)refreshNavBar {
    
    UIBarButtonItem *leftButton;
    UIBarButtonItem *rightButton;
    
    if (self.isEditing) {
        
        leftButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(userDidTapCancel:)];
        rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(userDidTapDone:)];
    }
    else if (self.mapView.selectedAnnotations.count > 0) {
        leftButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(userDidTapDeleteWaypoint:)];
        rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(userDidTapEditWaypoint:)];
    }
    
    [self.navigationBar.topItem setLeftBarButtonItem:leftButton animated:YES];
    [self.navigationBar.topItem setRightBarButtonItem:rightButton animated:YES];
}

@end
