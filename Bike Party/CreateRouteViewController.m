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
#import "TurnAnnotation.h"

@interface CreateRouteViewController ()

@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet CenterLockingMapView *mapView;

@property (strong, nonatomic) UILongPressGestureRecognizer *longPress;

@property (strong, nonatomic) id<MKAnnotation> editingAnnotation;
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
    
    self.longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    //self.tap.delegate = self;
    [self.mapView addGestureRecognizer:self.longPress];
}

#pragma mark - Gesture Recognizer Handlers
- (void)handleTap:(UITapGestureRecognizer *)tap {
    if (tap.state == UIGestureRecognizerStateEnded && self.mapView.selectedAnnotations.count == 0) {
        
        CGPoint tapPoint = [tap locationInView:self.mapView];
        CLLocationCoordinate2D tapCoordinate = [self.mapView convertPoint:tapPoint toCoordinateFromView:self.mapView];
        Waypoint *tapWaypoint = [self.ride addDestinationWithCoordinate:tapCoordinate];
        
        [self.mapView addAnnotation:tapWaypoint];
        [self beginEditingAnnotation:tapWaypoint];
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)longPress {
    if (longPress.state == UIGestureRecognizerStateBegan) {
        
        CGPoint longPressPoint = [longPress locationInView:self.mapView];
        CLLocationCoordinate2D longPressCoordinate = [self.mapView convertPoint:longPressPoint toCoordinateFromView:self.mapView];
        Waypoint *longPressWaypoint = [self.ride addDestinationWithCoordinate:longPressCoordinate];
        
        [self.mapView addAnnotation:longPressWaypoint];
        [self beginEditingAnnotation:longPressWaypoint];
    }
}

#pragma mark - Button Callbacks
- (void)userDidTapEdit:(UIBarButtonItem *)button {
    id <MKAnnotation> annotation = self.mapView.selectedAnnotations.firstObject;
    [self beginEditingAnnotation:annotation];
}

- (void)userDidTapDone:(UIBarButtonItem *)button {
    
    NSLog(@"confirm edits");
    
    if ([self.editingAnnotation isKindOfClass:[Waypoint class]]) {
        
        Waypoint *waypoint = (Waypoint *)self.editingAnnotation;
        [self.ride updateDestination:waypoint toCoordinate:self.mapView.centerCoordinate];
    }
    else if ([self.editingAnnotation isKindOfClass:[TurnAnnotation class]]) {
        
        TurnAnnotation *turnAnnotation = (TurnAnnotation *)self.editingAnnotation;
        [self.ride addViaPointInLeg:turnAnnotation.leg withCoordinate:self.mapView.centerCoordinate];
    }
    
    [self.mapView addAnnotation:self.editingAnnotation];
    [self endEditing];
    
    [self refreshNavBar];
    [self refreshRoute];
}

- (void)userDidTapCancel:(UIBarButtonItem *)button {
    
    [self.mapView addAnnotation:self.editingAnnotation];
    [self.mapView setCenterCoordinate:self.editingAnnotation.coordinate animated:YES];
    [self endEditing];
    
    [self refreshNavBar];
    [self refreshRoute];
}

- (void)userDidTapDelete:(UIBarButtonItem *)button {
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

- (void)beginEditingAnnotation:(id<MKAnnotation>)annotation {
    
    //When the pin and map are centered we use this
    self.editingAnnotation = annotation;
    self.transitioningToEditMode = YES;
    self.isEditing = YES;
    self.longPress.enabled = NO;
    
    self.mapView.lockCenterWhileZooming = YES;
    
    CLLocationCoordinate2D coordinate = annotation.coordinate;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinate, 0.005131, 0.004123);
    [self.mapView setRegion:region animated:YES];
    
    [self refreshNavBar];
}

- (void)endEditing {
    
    [self.mapView deselectAnnotation:self.editingAnnotation animated:YES];
    
    self.editingAnnotation = nil;
    self.isEditing = NO;
    self.longPress.enabled = YES;
    
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
    
    
    NSString *identifier = [self annotationIdentifierForAnnotation:annotation];
    MKAnnotationView *annotationView = [self.mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
    
    if (!annotationView) {
        if ([annotation isKindOfClass:[Waypoint class]]) {
            
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier: identifier];
            UIImage *image = [UIImage imageNamed:@"destinationMarker.png"];
            annotationView.image = image;
            annotationView.centerOffset = CGPointMake(0, -image.size.height / 2);
        }
        else if ([annotation isKindOfClass:[TurnAnnotation class]]) {
            
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
            UIImage *image = [UIImage imageNamed:@"turnMarker.png"];
            annotationView.image = image;
            annotationView.centerOffset = CGPointZero;
        }
    }
    
    return annotationView;
}

- (NSString *)annotationIdentifierForAnnotation:(id<MKAnnotation>)annotation {
    NSString *identifier;
    
    if ([annotation isKindOfClass:[Waypoint class]]) {
        
        Waypoint *waypoint = (Waypoint *)annotation;
        switch (waypoint.type) {
            case WaypointTypeDestination:
                identifier = @"destination";
                break;
            case WaypointTypeViaPoint:
                identifier = @"via";
                break;
                
            default:
                identifier = @"";
                NSLog(@"unknown waypoint type");
                break;
        }
    }
    else if ([annotation isKindOfClass:[TurnAnnotation class]]) {
        identifier = @"turn";
    }
    
    return identifier;
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    if (self.transitioningToEditMode) {
        
        //It might be worth using this unless it's nil.
        //MKAnnotationView *mapPin = [self.mapView viewForAnnotation:self.editingWaypoint];
        
        self.pinView = [self mapView:self.mapView viewForAnnotation:self.editingAnnotation];
        
        [self.mapView removeAnnotation:self.editingAnnotation];
        
        CGSize pinSize = self.pinView.frame.size;
        CGSize frameSize = self.mapView.frame.size;
        CGPoint offset = self.pinView.centerOffset;
        
        self.pinView.frame = CGRectMake(frameSize.width / 2 - pinSize.width / 2 + offset.x, frameSize.height / 2 - pinSize.height / 2 + offset.y, pinSize.width, pinSize.height);
        [self.mapView addSubview:self.pinView];
        
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
    else if ([view.annotation isKindOfClass:[TurnAnnotation class]]) {
        [self refreshNavBar];
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
    
    if (self.ride.turnAnnotations.count > 0) {
        [self.mapView addAnnotations:self.ride.turnAnnotations];
    }
    
    if (self.ride.waypoints.count > 0) {
        [self.mapView addAnnotations:self.ride.waypoints];
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
        leftButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(userDidTapDelete:)];
        rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(userDidTapEdit:)];
    }
    
    [self.navigationBar.topItem setLeftBarButtonItem:leftButton animated:YES];
    [self.navigationBar.topItem setRightBarButtonItem:rightButton animated:YES];
}

@end
