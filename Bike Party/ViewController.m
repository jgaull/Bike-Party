//
//  ViewController.m
//  Bike Party
//
//  Created by Jon on 11/11/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#define EDGE_PAD 0.01

#import "ViewController.h"
#import "MFLocationManager.h"
#import "GoogleDirectionsRequest.h"
#import "GoogleDirectionsRoute.h"
#import "RouteLeg.h"

typedef enum {
    kViewControllerStateViewing,
    kViewControllerStateEditing,
    kViewControllerStateDraggingPin
}ViewControllerState;

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *rightButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *leftButton;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (nonatomic) NSInteger state;

@property (strong, nonatomic) MFLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *userLocation;

@property (strong, nonatomic) MKPolyline *routePolyline;

//@property (strong, nonatomic) NSMutableArray *destinations;
@property (strong, nonatomic) RouteLeg *routeLeg;

@property (nonatomic) NSUInteger editingWaypointIndex;
@property (nonatomic) MKPinAnnotationView *draggingAnnotation;
@property (nonatomic) CGPoint lastTouchLocation;
@property (nonatomic) MKCoordinateSpan originalZoomLevel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.locationManager = [MFLocationManager new];
    self.rightButton.enabled = NO;
    
    __weak typeof(self) weakSelf = self;
    [self.locationManager findUserWithAccuracy:kCLLocationAccuracyHundredMeters andCallback:^(CLLocation *location, NSError *error) {
        weakSelf.userLocation = location;
        weakSelf.rightButton.enabled = YES;
        NSLog(@"Found user");
    }];
    
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [self.mapView addGestureRecognizer:longPressGesture];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)longPressGesture {
    NSLog(@"Long press state: %ld", longPressGesture.state);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[AddDestinationViewController class]]) {
        AddDestinationViewController *viewController = (AddDestinationViewController *)segue.destinationViewController;
        viewController.userLocation = self.userLocation;
        viewController.delegate = self;
    }
}

- (void)addDestinationView:(AddDestinationViewController *)addDestinationView userDidSelectDestination:(GooglePlace *)destination {
    
    if (!self.routeLeg) {
        self.routeLeg = [RouteLeg new];
    }
    
    if (!self.routeLeg.startPlace) {
        self.routeLeg.startPlace = destination;
    }
    else if (!self.routeLeg.endPlace) {
        self.routeLeg.endPlace = destination;
    }
    
    MKPointAnnotation *annotation = [MKPointAnnotation new];
    annotation.coordinate = destination.location.coordinate;
    annotation.title = destination.name;
    annotation.subtitle = destination.address;
    [self.mapView addAnnotation:annotation];
    
    /*
    NSInteger numberOfSteps = self.destinations.count;
    
    CLLocationCoordinate2D coordinates[numberOfSteps];
    for (NSInteger index = 0; index < numberOfSteps; index++) {
        GooglePlace *place = [self.destinations objectAtIndex:index];
        CLLocation *location = place.location;
        CLLocationCoordinate2D coordinate = location.coordinate;
        
        coordinates[index] = coordinate;
    }
    
    MKPolyline *polyLine = [MKPolyline polylineWithCoordinates:coordinates count:numberOfSteps];
    [self.mapView removeOverlay:self.routePolyline];
    self.routePolyline = polyLine;
    [self.mapView addOverlay:polyLine];
     */
    
    if (self.routeLeg.startPlace && self.routeLeg.endPlace) {
        [self refreshRoute];
    }
}

- (void)refreshRoute {
    
    __weak typeof(self) weakSelf = self;
    NSLog(@"Refresh route.");
    [self.routeLeg loadDirectionsWithCallback:^(GoogleDirectionsRoute *route, NSError *error) {
        if (!error) {
            [weakSelf performSelectorOnMainThread:@selector(drawMapWithRoute:) withObject:route waitUntilDone:NO];
        }
        else {
            NSLog(@"Flail: %@", error.localizedDescription);
        }
    }];
}

- (void)drawMapWithRoute:(GoogleDirectionsRoute *)route {
    
    MKPolyline *polyLine = route.overviewPolyline;
    [self.mapView removeOverlay:self.routePolyline];
    self.routePolyline = polyLine;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mapView addOverlay:polyLine];
    });
    
    if (self.state != kViewControllerStateEditing) {
        MKCoordinateSpan span = route.bounds.span;
        MKCoordinateSpan paddedSpan = MKCoordinateSpanMake(span.latitudeDelta + EDGE_PAD, span.longitudeDelta + EDGE_PAD);
        MKCoordinateRegion paddedRegion = MKCoordinateRegionMake(route.bounds.center, paddedSpan);
        
        [self.mapView setRegion:paddedRegion animated:YES];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    MKPinAnnotationView *pin = (MKPinAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier: @"destinationPin"];
    if (pin == nil) {
        pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier: @"destinationPin"];
        UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
        UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        
        pin.animatesDrop = YES;
        pin.canShowCallout = YES;
        pin.rightCalloutAccessoryView = rightButton;
        pin.leftCalloutAccessoryView = leftButton;
        pin.draggable = YES;
        
    } else {
        pin.annotation = annotation;
    }
    
    return pin;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    
    MKPolylineRenderer *polylineRenderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
    polylineRenderer.strokeColor = [UIColor redColor];
    polylineRenderer.lineWidth = 3.0;
    
    return polylineRenderer;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    NSLog(@"Did select view: %@", view.annotation.title);
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    
    //NSInteger index = [self indexOfSelectedAnnotationView:view];
    
    if (control == view.rightCalloutAccessoryView) {
        NSLog(@"Add a new waypoint");
    }
    else {
        NSLog(@"Edit this waypoint");
        [view setDragState:MKAnnotationViewDragStateStarting animated:YES];
    }
    
    /*
    CLLocationCoordinate2D centerCoordinate = self.mapView.centerCoordinate;
    CLLocation *viewCenter = [[CLLocation alloc] initWithLatitude:centerCoordinate.latitude longitude:centerCoordinate.longitude];
    [self.routeLeg.waypoints insertObject:viewCenter atIndex:index];
    [self refreshRoute];
     */
    
    self.state = kViewControllerStateEditing;
    [self refreshView];
    
    /*
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Place Waypoint" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if (index > 0) {
        UIAlertAction *beforeDestinationAction = [UIAlertAction actionWithTitle:@"Before Destination" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSLog(@"Before Destination");
            [self beginEditingWaypoint:editingWaypoint];
        }];
        
        [alert addAction:beforeDestinationAction];
    }
    
    if (index < self.routeLeg.locations.count - 1) {
        UIAlertAction *afterDestinationAction = [UIAlertAction actionWithTitle:@"After Destination" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self beginEditingWaypoint:editingWaypoint];
        }];
        
        [alert addAction:afterDestinationAction];
    }
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
     */
}

/*
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.state == kViewControllerStateDraggingPin) {
        UITouch *touch = touches.anyObject;
        CGPoint locationInView = [touch locationInView:self.mapView];
        CGFloat distance = hypot(locationInView.x - self.lastTouchLocation.x, locationInView.y - self.lastTouchLocation.y);
        NSLog(@"distance: %f", distance);
    }
    
    NSLog(@"touches moved");
}
 
 */

/*
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
    
    if (newState == MKAnnotationViewDragStateDragging) {
        self.state = kViewControllerStateDraggingPin;
        
        self.originalZoomLevel = self.mapView.region.span;
        
        if ([view isKindOfClass:[MKPinAnnotationView class]]) {
            self.draggingAnnotation = (MKPinAnnotationView *)view;
        }
        
        [view addObserver:self forKeyPath:@"center" options:NSKeyValueObservingOptionNew context:nil];
        
        NSLog(@"lattitude delta: %f, longitude delta: %f", self.mapView.region.span.latitudeDelta, self.mapView.region.span.longitudeDelta);
        
        //MKCoordinateSpan span = MKCoordinateSpanMake(0.008297, 0.006666);
        //MKCoordinateRegion region = MKCoordinateRegionMake(view.annotation.coordinate, span);
        
        [self performSelectorOnMainThread:@selector(zoomMap) withObject:nil waitUntilDone:NO];
        
        //[self.mapView setRegion:region animated:YES];
    }
    else if (newState == MKAnnotationViewDragStateNone) {
        self.state = kViewControllerStateViewing;
        
        self.draggingAnnotation = nil;
        [view removeObserver:self forKeyPath:@"center"];
    }
}
 */

- (void)zoomMap {
    MKCoordinateSpan span = MKCoordinateSpanMake(0.008297, 0.006666);
    MKCoordinateRegion region = MKCoordinateRegionMake(self.mapView.centerCoordinate, span);
    [self.mapView setRegion:region animated:YES];
}

/*
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    CGPoint position = myAnnotationView.center;
    //... here take  myAnnotationView.centerOffset into consideration to get the correct coordinate
    CLLocationCoordinate2D newCoordinate = [self.mapView convertPoint:position toCoordinateFromView:self.superview];
    
    CGPoint locationInView = self.draggingAnnotation.center;
    CGFloat distance = hypot(locationInView.x - self.lastTouchLocation.x, locationInView.y - self.lastTouchLocation.y);
    NSLog(@"distance: %f", distance);
    
    self.lastTouchLocation = locationInView;
    
    if (distance > 10) {
        MKCoordinateSpan span = self.originalZoomLevel;
        CLLocationCoordinate2D center = [self.mapView convertPoint:locationInView toCoordinateFromView:self.mapView];
        MKCoordinateRegion region = MKCoordinateRegionMake(center, span);
        
        //[self.mapView setRegion:region animated:YES];
    }
}
*/

- (NSInteger)indexOfSelectedAnnotationView:(MKAnnotationView *)view {
    CLLocationCoordinate2D annotationCoordinate = view.annotation.coordinate;
    NSInteger index = -1;
    
    CLLocationCoordinate2D startCoordinate = self.routeLeg.startPlace.location.coordinate;
    CLLocationCoordinate2D endCoordinate = self.routeLeg.endPlace.location.coordinate;
    if ([self coordinate:startCoordinate isEqualToCoordinate:annotationCoordinate]) {
        
        index = 0;
    }
    else if ([self coordinate:endCoordinate isEqualToCoordinate:annotationCoordinate]) {
        
        index = self.routeLeg.waypoints.count;
    }
    else {
        
        for (int i = 0; i < self.routeLeg.waypoints.count; i++) {
            
            CLLocation *waypointLocation = self.routeLeg.waypoints[i];
            if ([self coordinate:waypointLocation.coordinate isEqualToCoordinate:annotationCoordinate]) {
                
                index = i + 1;
                break;
            }
        }
    }
    
    return index;
}

- (BOOL)coordinate:(CLLocationCoordinate2D)coordinate1 isEqualToCoordinate:(CLLocationCoordinate2D)coordinate2 {
    if (coordinate1.latitude == coordinate2.latitude &&
        coordinate1.longitude == coordinate2.longitude) {
        return YES;
    }
    
    return NO;
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    /*
    if (self.state == kViewControllerStateEditing) {
        
        NSLog(@"The point has moved.");
        
        CLLocationCoordinate2D centerCoordinate = self.mapView.centerCoordinate;
        CLLocation *newLocation = [[CLLocation alloc] initWithLatitude:centerCoordinate.latitude longitude:centerCoordinate.longitude];
        [self.routeLeg.waypoints replaceObjectAtIndex:self.editingWaypointIndex withObject:newLocation];
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshRoute) object:nil];
        [self performSelector:@selector(refreshRoute) withObject:nil afterDelay:1];
    }
     */
}

- (void)endEditing {
    
    self.state = kViewControllerStateViewing;
    [self refreshView];
}

- (void)cancelEditingWaypoint {
    [self endEditing];
}

- (void)doneEditingWaypoint {
    [self endEditing];
}

- (IBAction)userDidTapAddLeg:(UIBarButtonItem *)sender {
    [self performSegueWithIdentifier:@"addLegSegue" sender:self];
}


//Update the UI Between state changes.
- (void)refreshView {
    
    UIBarButtonItem *leftButton;
    UIBarButtonItem *rightButton;
    
    switch (self.state) {
        case kViewControllerStateViewing:
            rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(userDidTapAddLeg:)];
            break;
            
        case kViewControllerStateEditing:
            leftButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelEditingWaypoint)];
            rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditingWaypoint)];
            break;
            
        default:
            break;
    }
    
    [self.navigationBar.topItem setLeftBarButtonItem:leftButton animated:YES];
    [self.navigationBar.topItem setRightBarButtonItem:rightButton animated:YES];
}

@end
