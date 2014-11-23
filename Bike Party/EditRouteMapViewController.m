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

@property (strong, nonatomic) MKAnnotationView *pinView;
@property (nonatomic) BOOL transitioningToEditMode;

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
    
    [self.mapView addAnnotation:self.editingWaypoint];
    
    [self endEditing];
}

- (void)cancelEdits {
    [self.mutableWaypoints removeObject:self.editingWaypoint];
    [self endEditing];
}

- (void)addPolyline:(MKPolyline *)polyline withIdentifier:(id <NSCopying>)identifier {
    
    MKPolyline *previousPolyline = [self.polylines objectForKey:identifier];
    if (previousPolyline) {
        [self removePolylineWithIdentifier:identifier];
    }
    
    [self.polylines setObject:polyline forKey:identifier];
    [self.mapView addOverlay:polyline];
}

- (void)removePolylineWithIdentifier:(id <NSCopying>)identifier {
    
    MKPolyline *polyline = [self.polylines objectForKey:identifier];
    if (polyline) {
        [self.mapView removeOverlay:polyline];
        [self.polylines removeObjectForKey:identifier];
    }
}

- (void)showPolylineWithIdentifier:(id <NSCopying>)identifier edgePadding:(CGFloat)edgeInsets animated:(BOOL)animated {
    
    MKPolyline *polyline = [self.polylines objectForKey:identifier];
    if (polyline) {
        MKMapRect mapRect = polyline.boundingMapRect;
        UIEdgeInsets padding = UIEdgeInsetsMake(edgeInsets, edgeInsets, edgeInsets, edgeInsets);
        [self.mapView setVisibleMapRect:mapRect edgePadding:padding animated:animated];
    }
}

- (void)showPolylinesWithIdentifiers:(NSArray *)identifiers edgePadding:(CGFloat)edgeInsets animated:(BOOL)animated {
    
    MKMapRect boundingBox = MKMapRectNull;
    for (id <NSCopying> identifier in identifiers) {
        MKPolyline *polyline = [self.polylines objectForKey:identifier];
        
        if (MKMapRectIsNull(boundingBox)) {
            boundingBox = polyline.boundingMapRect;
        }
        else {
            boundingBox = MKMapRectUnion(boundingBox, polyline.boundingMapRect);
        }
    }
    
    UIEdgeInsets padding = UIEdgeInsetsMake(edgeInsets, edgeInsets, edgeInsets, edgeInsets);
    [self.mapView setVisibleMapRect:boundingBox edgePadding:padding animated:animated];
}

- (void)insertWaypoint:(Waypoint *)waypoint atIndex:(NSUInteger)index {
    [self.mutableWaypoints insertObject:waypoint atIndex:index];
    [self.mapView addAnnotation:waypoint];
}

- (void)addWaypoint:(Waypoint *)waypoint {
    [self.mutableWaypoints addObject:waypoint];
    [self.mapView addAnnotation:waypoint];
}

- (void)removeWaypoint:(Waypoint *)waypoint {
    [self.mapView removeAnnotation:waypoint];
    [self.mutableWaypoints removeObject:waypoint];
    
    if (waypoint == self.selectedWaypoint) {
        [self deselectSelectedWaypoint];
    }
}

- (void)beginEditingWaypoint:(Waypoint *)waypoint {
    
    //When the pin and map are centered we use this
    _editingWaypoint = waypoint;
    self.transitioningToEditMode = YES;
    
    CLLocationCoordinate2D coordinate = waypoint.coordinate;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinate, 0.005131, 0.004123);
    [self.mapView setRegion:region animated:YES];
    
    [self.mapView removeGestureRecognizer:self.longPress];
    [self.mapView removeGestureRecognizer:self.tap];
    
    [self.mapView addGestureRecognizer:self.touch];
    [self.mapView addGestureRecognizer:self.pinch];
    [self.mapView addGestureRecognizer:self.doubleTap];
    [self.mapView addGestureRecognizer:self.pan];
    
    self.mapView.zoomEnabled = NO;
    
    _state = EditRouteMapViewControllerStateEditingWaypoint;
    
    if ([self.delegate respondsToSelector:@selector(editRouteMap:didBeginEditingWaypoint:)]) {
#warning Waypoint parameter should not be nil
        [self.delegate editRouteMap:self didBeginEditingWaypoint:nil];
    }
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
    //the single tap to fail in the event of a double tap.
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
        
        CGPoint tapPoint = [tap locationInView:self.mapView];
        
        if (self.selectedWaypoint) {
            MKAnnotationView *annotationView = [self.mapView viewForAnnotation:self.selectedWaypoint];
            [annotationView setSelected:NO animated:YES];
            
            Waypoint *waypoint = self.selectedWaypoint;
            _selectedWaypoint = nil;
            
            if ([self.delegate respondsToSelector:@selector(editRouteMap:didDeselectWaypoint:)]) {
                
                [self.delegate editRouteMap:self didDeselectWaypoint:waypoint];
            }
            
            return;
        }
        
        for (Waypoint *waypoint in self.mapView.annotations) {
            
            MKAnnotationView *annotationView = [self.mapView viewForAnnotation:waypoint];
            CGRect frame = annotationView.frame;
            
            if (CGRectContainsPoint(frame, tapPoint)) {
                
                _selectedWaypoint = waypoint;
                [annotationView setSelected:YES animated:YES];
                
                if ([self.delegate respondsToSelector:@selector(editRouteMap:didSelectWaypoint:)]) {
                    [self.delegate editRouteMap:self didSelectWaypoint:waypoint];
                }
                
                return;
            }
        }
        
        if ([self.delegate respondsToSelector:@selector(editRouteMap:didSelectCoordinate:)]) {
            
            CGPoint touchPoint = [tap locationInView:self.mapView];
            CLLocationCoordinate2D coordinate = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
            
            [self.delegate editRouteMap:self didSelectCoordinate:coordinate];
        }
        
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)longPress {
    if (longPress.state == UIGestureRecognizerStateBegan) {
        
        CGPoint touchPoint = [longPress locationInView:self.mapView];
        
        for (id <NSCopying> key in self.polylines) {
            MKPolyline *polyline = [self.polylines objectForKey:key];
            
            for (int i = 0; i < polyline.pointCount - 1; i++) {
                MKMapPoint mapPoint1 = polyline.points[i];
                MKMapPoint mapPoint2 = polyline.points[i + 1];
                
                CGPoint point1 = [self convertMapPointToPoint:mapPoint1];
                CGPoint point2 = [self convertMapPointToPoint:mapPoint2];
                
                CGPoint intersection = [self testSegmentWithStartPoint:point1 endPoint:point2 forIntersectionWithCircleAtPoint:touchPoint withRadius:15];
                if (!CGPointEqualToPoint(intersection, CGPointZero)) {
                    //NSLog(@"intersect!");
                    
                    if ([self.delegate respondsToSelector:@selector(editRouteMap:didSelectPolyline:atCoordinate:)]) {
                        
                        CLLocationCoordinate2D coordinate = [self.mapView convertPoint:intersection toCoordinateFromView:self.mapView];
                        
                        [self.delegate editRouteMap:self didSelectPolyline:key atCoordinate:coordinate];
                    }
                    
                    return;
                }
            }
        }
        
        if ([self.delegate respondsToSelector:@selector(editRouteMap:didSelectCoordinate:)]) {
            
            CLLocationCoordinate2D coordinate = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
            [self.delegate editRouteMap:self didSelectCoordinate:coordinate];
        }
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

/*
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    NSLog(@"annotation selected");
    
    if ([self.delegate respondsToSelector:@selector(editRouteMap:didSelectWaypoint:)]) {
        Waypoint *waypoint = [self waypointForAnnotationView:view];
        [self.delegate editRouteMap:self didSelectWaypoint:waypoint];
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    NSLog(@"annotation deselected");
    
    if ([self.delegate respondsToSelector:@selector(editRouteMap:didDeselectWaypoint:)]) {
        Waypoint *waypoint = [self waypointForAnnotationView:view];
        [self.delegate editRouteMap:self didDeselectWaypoint:waypoint];
    }
}
 */

/*
- (Waypoint *)waypointForAnnotationView:(MKAnnotationView *)view {
    for (Waypoint *waypoint in self.waypoints) {
        
        CLLocationCoordinate2D coordinate1 = waypoint.coordinate;
        CLLocationCoordinate2D coordinate2 = view.annotation.coordinate;
        if (coordinate1.latitude == coordinate2.latitude && coordinate1.longitude == coordinate2.longitude) {
            return waypoint;
        }
    }
    
    return nil;
}
 */

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    if (self.transitioningToEditMode) {
        
        MKAnnotationView *mapPin = [self.mapView viewForAnnotation:self.editingWaypoint];
        
        [self.mapView removeAnnotation:self.editingWaypoint];
        
        CGSize pinSize = mapPin.frame.size;
        CGSize frameSize = self.mapView.frame.size;
        CGPoint offset = mapPin.centerOffset;

        mapPin.frame = CGRectMake(frameSize.width / 2 - pinSize.width / 2 + offset.x, frameSize.height / 2 - pinSize.height / 2 + offset.y, pinSize.width, pinSize.height);
        [self.mapView addSubview:mapPin];

        self.pinView = mapPin;
        
        self.transitioningToEditMode = NO;
    }
    else if (self.editingWaypoint) {
        self.editingWaypoint.coordinate = self.mapView.centerCoordinate;
        
        if ([self.delegate respondsToSelector:@selector(editRouteMap:didUpdateEditingWaypoint:)]) {
            [self.delegate editRouteMap:self didUpdateEditingWaypoint:self.editingWaypoint];
        }
    }
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    
    MKPolylineRenderer *polylineRenderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
    polylineRenderer.strokeColor = [UIColor colorWithRed:0.9843137255 green:0.4470588235 blue:0.1450980392 alpha:1];
    polylineRenderer.lineWidth = 4.0;
    
    return polylineRenderer;
}

#pragma mark - UIGestureRecognizerDelegate Methods
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    return YES;
}

#pragma mark - helper methods
- (void)deselectSelectedWaypoint {
    
    MKAnnotationView *annotationView = [self.mapView viewForAnnotation:self.selectedWaypoint];
    [annotationView setSelected:NO animated:YES];
    
    Waypoint *waypoint = self.selectedWaypoint;
    _selectedWaypoint = nil;
    
    if ([self.delegate respondsToSelector:@selector(editRouteMap:didDeselectWaypoint:)]) {
        
        [self.delegate editRouteMap:self didDeselectWaypoint:waypoint];
    }
}

- (void)endEditing {
    _editingWaypoint = nil;
    
    [self.pinView removeFromSuperview];
    self.pinView = nil;
    
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

- (CGPoint)convertMapPointToPoint:(MKMapPoint)mapPoint {
    CLLocationCoordinate2D coordinate = MKCoordinateForMapPoint(mapPoint);
    return [self.mapView convertCoordinate:coordinate toPointToView:self.mapView];
}

- (CGPoint)testSegmentWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint forIntersectionWithCircleAtPoint:(CGPoint)circleCenter withRadius:(double)radius {
    
    /*
     //Unit test this bad boy.
     CGPoint point1 = CGPointMake(129.94014059437251, 14.406687876805409);
     CGPoint point2 = CGPointMake(154.11791754429751, 346.77986183622789);
     CGPoint circleCenter = CGPointMake(130.5, 218);
     double radius = 50;
     
     //CGPoint point1 = CGPointMake(0, 0);
     //CGPoint point2 = CGPointMake(5, 10);
     //CGPoint circleCenter = CGPointMake(1, 3);
     //double radius = 1;
     BOOL intersection = [self testSegmentWithStartPoint:point1 endPoint:point2 forIntersectionWithCircleAtPoint:circleCenter withRadius:radius];
     NSLog(@"intersection? %d", intersection);
     */
    
    //If the line is vertical
    if (startPoint.x == endPoint.x) {
        
        double distance = ABS(startPoint.x - circleCenter.x);
        if (distance <= radius) {
            return CGPointMake(startPoint.x, circleCenter.y);
        }
    }
    
    //The line is horizontal
    if (startPoint.y == endPoint.y) {
        
        double distance = ABS(startPoint.y - circleCenter.y);
        if (distance <= radius) {
            return CGPointMake(circleCenter.x, startPoint.y);
        }
    }
    
    //Check to see if either of the end points of this segment are within the circle
    double distanceFromStartPoint = [self distanceBetweenPoint:startPoint andPoint:circleCenter];
    double distanceFromEndPoint = [self distanceBetweenPoint:endPoint andPoint:circleCenter];
    
    if (distanceFromStartPoint <= radius) {
        //The circle contains either the start or end point
        return startPoint;
    }
    else if (distanceFromEndPoint <= radius) {
        return endPoint;
    }
    
    //Cover the other cases with some trig
    double run = endPoint.x - startPoint.x;
    double rise = endPoint.y - startPoint.y;
    double slope = rise / run;
    double yIntercept = startPoint.y - slope * startPoint.x;
    
    //y = m * x + b
    double y = circleCenter.y;
    double x = (y - yIntercept) / slope;
    CGPoint newPoint = CGPointMake(x, y);
    
    double lengthOfLine = circleCenter.x - newPoint.x;
    double angle = ABS(atan(slope) * (180 / M_PI));
    
    //NSLog(@"angle = %f, sin(angle) = %f", angle, sin(angle));
    double distance = lengthOfLine * sin(angle);
    
    if (ABS(distance) <= radius) {
        double intersectionX = circleCenter.x + distance * ABS(sin(angle));
        double intersectionY = circleCenter.y + distance * ABS(cos(angle));
        CGPoint intersectionPoint = CGPointMake(intersectionX, intersectionY);
        CGPoint bottomLeft = CGPointMake(MIN(startPoint.x, endPoint.x), MIN(startPoint.y, endPoint.y));
        CGPoint topRight = CGPointMake(MAX(startPoint.x, endPoint.x), MAX(startPoint.y, endPoint.y));
        CGRect lineSegmentBoundingBox = CGRectMake(bottomLeft.x, bottomLeft.y, topRight.x - bottomLeft.x, topRight.y - bottomLeft.y);
        
        if (CGRectContainsPoint(lineSegmentBoundingBox, intersectionPoint)) {
            //NSLog(@"distance: %f", distance);
            return intersectionPoint;
        }
    }
    
    //None of those methods worked?! I guess we'll have to accept defeat.
    //No amount of math can prove that this segment intercects the circle.
    return CGPointZero; //Maybe there's a better way to do this?
}

- (double)distanceBetweenPoint:(CGPoint)point1 andPoint:(CGPoint)point2 {
    return ABS(hypot((point1.x - point2.x), (point1.y - point2.y)));
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
