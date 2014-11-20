//
//  TestMapViewController.m
//  Bike Party
//
//  Created by Jon on 11/15/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import "EditRouteMapViewController.h"
#import "TouchGestureRecognizer.h"

@interface EditRouteMapViewController ()

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (nonatomic) BOOL didDropPin;
@property (strong, nonatomic) MKPinAnnotationView *pinView;
@property (strong, nonatomic) MKPointAnnotation *editingAnnotation;

@property (strong, nonatomic) UILongPressGestureRecognizer *longPress;
@property (strong, nonatomic) UITapGestureRecognizer *tap;
@property (strong, nonatomic) UIPanGestureRecognizer *pan;
@property (strong, nonatomic) UIPinchGestureRecognizer *pinch;
@property (strong, nonatomic) UITapGestureRecognizer *doubleTap;
@property (strong, nonatomic) TouchGestureRecognizer *touch;

@property (nonatomic) MKCoordinateRegion originalRegion;
@property (strong, nonatomic) CLLocation *originalCenter;

@property (strong, nonatomic) NSMutableArray *mutableWaypoints;
@property (strong, nonatomic) NSMutableDictionary *polylines;

@end

@implementation EditRouteMapViewController

#pragma mark - Public Interface
- (void)confirmEdits {
    CLLocationCoordinate2D coordinate;
    if (self.originalCenter) {
        coordinate = self.originalCenter.coordinate;
    }
    else {
        coordinate = self.mapView.centerCoordinate;
    }
    
    self.editingAnnotation.coordinate = coordinate;
    [self.mapView addAnnotation:self.editingAnnotation];
    
    Waypoint *waypoint = [[Waypoint alloc] initWithCoordinate:coordinate andName:nil];
    [self.mutableWaypoints addObject:waypoint];
    
    [self endEditing];
}

- (void)cancelEdits {
    [self endEditing];
}

- (void)addPolyline:(MKPolyline *)polyline withIdentifier:(NSString *)identifier {
    
    MKPolyline *previousPolyline = [self.polylines objectForKey:identifier];
    if (previousPolyline) {
        [self removePolylineWithIdentifier:identifier];
    }
    
    [self.polylines setObject:polyline forKey:identifier];
    [self.mapView addOverlay:polyline];
}

- (void)removePolylineWithIdentifier:(NSString *)identifier {
    
    MKPolyline *polyline = [self.polylines objectForKey:identifier];
    if (polyline) {
        [self.mapView removeOverlay:polyline];
        [self.polylines removeObjectForKey:identifier];
    }
}

- (void)showPolylineWithIdentifier:(NSString *)identifier animated:(BOOL)animated {
    /*
    if (self.state != kViewControllerStateEditing) {
        MKCoordinateSpan span = route.bounds.span;
        MKCoordinateSpan paddedSpan = MKCoordinateSpanMake(span.latitudeDelta + EDGE_PAD, span.longitudeDelta + EDGE_PAD);
        MKCoordinateRegion paddedRegion = MKCoordinateRegionMake(route.bounds.center, paddedSpan);
        
        [self.mapView setRegion:paddedRegion animated:YES];
    }
     */
}

#pragma mark - UIViewController overrides
- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    //long press is used to add waypoints
    self.longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [self.mapView addGestureRecognizer:self.longPress];
    
    //tap is also used to add waypoints
    self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    
    //The default double tap behavior (zoom the map in) conflicts with our single tap.
    //We fix this problem by finding the double tap gesture recognizer and requiring
    //The single tap to fail in the event of a double tap
    for (UIView *view in self.mapView.subviews) {
        for (UIGestureRecognizer *gesture in view.gestureRecognizers) {
            if ([gesture isKindOfClass:[UITapGestureRecognizer class]]) {
                
                UITapGestureRecognizer *tap = (UITapGestureRecognizer *)gesture;
                if (tap.numberOfTapsRequired == 2) {
                    [self.tap requireGestureRecognizerToFail:tap];
                }
            }
        }
    }
    
    [self.mapView addGestureRecognizer:self.tap];
    
    //Pinch used for zooming in and out while editing
    self.pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    self.pinch.delegate = self;
    self.pinch.cancelsTouchesInView = YES;
    
    //Pan is used to determine when the user moves the map so we can
    //properly lock and unlock the center while editing
    self.pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    self.pan.maximumNumberOfTouches = 1;
    self.pan.delegate = self;
    
    //Double tap is used to manually override the default double tap to zoom
    //We need to do this to keep the center locked while editing.
    self.doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    self.doubleTap.numberOfTapsRequired = 2;
    self.doubleTap.cancelsTouchesInView = YES;
    
    //This prevents the zoom in and out momentum from overriding our pan gestures.
    //We cancel the momentum as soon as the user touches the screen.
    self.touch = [[TouchGestureRecognizer alloc] initWithTarget:self action:@selector(handleTouch:)];
    self.touch.delegate = self;
}

#pragma mark - UIGestureRecognizer handlers
- (void)handleTap:(UITapGestureRecognizer *)tap {
    if (tap.state == UIGestureRecognizerStateEnded) {
        [self beginEditingWithGesture:tap];
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)longPress {
    if (longPress.state == UIGestureRecognizerStateBegan) {
        [self beginEditingWithGesture:longPress];
    }
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)doubleTap {
    //NSLog(@"Double tap: %ld", doubleTap.state);
    
    if (doubleTap.state == UIGestureRecognizerStateEnded) {
        
        [self cancelScrollingUpdate];
        
        float zoomMultiplier = 0.5;
        MKCoordinateSpan currentSpan = self.mapView.region.span;
        MKCoordinateSpan zoomedSpan = MKCoordinateSpanMake(currentSpan.latitudeDelta * zoomMultiplier, currentSpan.longitudeDelta * zoomMultiplier);
        
        CLLocationCoordinate2D targetCenter;
        if (self.originalCenter) {
            targetCenter = self.originalCenter.coordinate;
        }
        else {
            targetCenter = self.mapView.centerCoordinate;
        }
        
        [self.mapView setRegion:MKCoordinateRegionMake(targetCenter, zoomedSpan) animated:YES];
    }
}

- (void)handlePinch:(UIPinchGestureRecognizer *)pinch {
    
    if (pinch.state == UIGestureRecognizerStateBegan) {
        //NSLog(@"pinch began");
        
        [self cancelScrollingUpdate];
        
        self.mapView.scrollEnabled = NO;
        
        if (!self.originalCenter) {
            CLLocationCoordinate2D centerCoordinate = self.mapView.centerCoordinate;
            self.originalCenter = [[CLLocation alloc] initWithLatitude:centerCoordinate.latitude longitude:centerCoordinate.longitude];
        }
        
        self.originalRegion = self.mapView.region;
    }
    else if (pinch.state == UIGestureRecognizerStateChanged) {
        //NSLog(@"pinch changed");
        
        double latdelta = self.originalRegion.span.latitudeDelta / pinch.scale;
        double londelta = self.originalRegion.span.longitudeDelta / pinch.scale;
        latdelta = MAX(MIN(latdelta, 150), 0);
        londelta = MAX(MIN(londelta, 150), 0);
        MKCoordinateSpan span = MKCoordinateSpanMake(latdelta, londelta);
        
        [self.mapView setRegion:MKCoordinateRegionMake(self.originalCenter.coordinate, span) animated:NO];
    }
    else if (pinch.state == UIGestureRecognizerStateCancelled) {
        //NSLog(@"pinch cancelled");
        self.mapView.scrollEnabled = YES;
    }
    else if (pinch.state == UIGestureRecognizerStateEnded) {
        //NSLog(@"pinch ended");
        self.mapView.scrollEnabled = YES;
        [self mapZoomUpdatesLoop];
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    
    if (pan.state == UIGestureRecognizerStateBegan) {
        //NSLog(@"pan began");
        self.originalCenter = nil;
        [self cancelScrollingUpdate];
    }
}

- (void)handleTouch:(TouchGestureRecognizer *)touch {
    if (touch.state == UIGestureRecognizerStateBegan) {
        [self cancelScrollingUpdate];
    }
}

#pragma mark - MKMapViewDelegate Methods
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
        //pin.draggable = YES;
        
    } else {
        pin.annotation = annotation;
    }
    
    return pin;
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    if (self.didDropPin) {
        self.didDropPin = NO;
        
        MKPinAnnotationView *mapPin = [[MKPinAnnotationView alloc] initWithAnnotation:self.editingAnnotation reuseIdentifier:@"testPin"];

        CGSize pinSize = mapPin.frame.size;
        CGSize frameSize = self.mapView.frame.size;
        CGPoint offset = mapPin.centerOffset;

        mapPin.frame = CGRectMake(frameSize.width / 2 - offset.x, frameSize.height / 2 - pinSize.height - offset.y - 10, pinSize.width, pinSize.height);
        [self.mapView addSubview:mapPin];

        self.pinView = mapPin;
        
        [self.mapView removeAnnotation:self.editingAnnotation];
    }
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    
    MKPolylineRenderer *polylineRenderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
    polylineRenderer.strokeColor = [UIColor redColor];
    polylineRenderer.lineWidth = 3.0;
    
    return polylineRenderer;
}

#pragma mark - UIGestureRecognizerDelegate Methods
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    return YES;
}

#pragma mark - helper methods
- (void)beginEditingWithGesture:(UIGestureRecognizer *)gesture {
    
    //When the pin and map are centered we use this
    self.didDropPin = YES;
    
    //Determine the location of the touch
    CGPoint touchPoint = [gesture locationInView:self.mapView];
    CLLocationCoordinate2D locationOnMap = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
    
    //Create an annotation to add a pin to the map
    MKPointAnnotation *annotation = [MKPointAnnotation new];
    annotation.coordinate = locationOnMap;
    self.editingAnnotation = annotation;
    [self.mapView addAnnotation:annotation];
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(locationOnMap, 0.005131, 0.004123);
    [self.mapView setRegion:region animated:YES];
    
    [self.mapView removeGestureRecognizer:self.longPress];
    [self.mapView removeGestureRecognizer:self.tap];
    
    [self.mapView addGestureRecognizer:self.touch];
    [self.mapView addGestureRecognizer:self.pinch];
    [self.mapView addGestureRecognizer:self.doubleTap];
    [self.mapView addGestureRecognizer:self.pan];
    
    self.mapView.zoomEnabled = NO;
    
    _state = EditRouteMapViewControllerStateEditing;
    
    if ([self.delegate respondsToSelector:@selector(editRouteMap:didBeginEditingWaypoint:)]) {
#warning Waypoint parameter should not be nil
        [self.delegate editRouteMap:self didBeginEditingWaypoint:nil];
    }
}


- (void)endEditing {
    [self.pinView removeFromSuperview];
    self.pinView = nil;
    //self.annotation = nil;
    
    [self.mapView addGestureRecognizer:self.longPress];
    [self.mapView addGestureRecognizer:self.tap];
    
    [self.mapView removeGestureRecognizer:self.pinch];
    [self.mapView removeGestureRecognizer:self.doubleTap];
    [self.mapView removeGestureRecognizer:self.touch];
    [self.mapView removeGestureRecognizer:self.pan];
    
    self.mapView.zoomEnabled = YES;
    
    _state = EditRouteMapViewControllerStateIdle;
    
    if ([self.delegate respondsToSelector:@selector(editRouteMap:didEndEditingWaypoint:)]) {
#warning Waypoint parameter should not be nil
        [self.delegate editRouteMap:self didEndEditingWaypoint:nil];
    }
}

static float velocityDecay = 0.9;
static float otherVelocityDecay = 0.75;
static float maxVelocity = 8;
static float pinchScale;
static float currentVelocity;
static NSDate *lastRun;
- (void)mapZoomUpdatesLoop {
    
    if (!lastRun) {
        lastRun = [NSDate date];
        currentVelocity = MIN(self.pinch.velocity, maxVelocity);
        pinchScale = self.pinch.scale;
    }
    
    float timeSinceLastRun = ABS([lastRun timeIntervalSinceNow]);
    
    float decay = currentVelocity > 0 ? velocityDecay : otherVelocityDecay;
    currentVelocity *= decay;
    pinchScale = currentVelocity * timeSinceLastRun;
    
    double latitudeDelta = self.mapView.region.span.latitudeDelta * (1 - pinchScale);
    double longitudeDelta = self.mapView.region.span.longitudeDelta * (1 - pinchScale);
    float minDelta = 0.003432;
    float maxDelta = 150;
    latitudeDelta = MAX(MIN(latitudeDelta, maxDelta), minDelta);
    longitudeDelta = MAX(MIN(longitudeDelta, maxDelta), minDelta);
    MKCoordinateSpan span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta);
    
    [self.mapView setRegion:MKCoordinateRegionMake(self.originalCenter.coordinate, span) animated:NO];
    
    if (ABS(currentVelocity) > 0.05 && latitudeDelta < maxDelta && latitudeDelta > minDelta && longitudeDelta < maxDelta && longitudeDelta > minDelta) {
        
        lastRun = [NSDate date];
        [self performSelector:@selector(mapZoomUpdatesLoop) withObject:nil afterDelay:1.0 / 120];
    }
    else {
        //NSLog(@"Zoom over.");
        lastRun = nil;
    }
}

- (void)cancelScrollingUpdate {
    lastRun = nil;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(mapZoomUpdatesLoop) object:nil];
}

#pragma mark - Getters and Setters
- (NSMutableArray *)mutableWaypoints {
    if (!_mutableWaypoints) {
        _mutableWaypoints = [NSMutableArray new];
    }
    return _mutableWaypoints;
}

- (NSMutableDictionary *)polylines {
    if (!_polylines) {
        _polylines = [NSMutableDictionary new];
    }
    return _polylines;
}

- (NSArray *)waypoints {
    return [NSArray arrayWithArray:self.mutableWaypoints];
}

@end
