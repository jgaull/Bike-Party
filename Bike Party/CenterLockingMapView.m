//
//  TestMapViewController.m
//  Bike Party
//
//  Created by Jon on 11/15/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import "CenterLockingMapView.h"
#import "TouchGestureRecognizer.h"

@interface CenterLockingMapView ()

@property (strong, nonatomic) UIPanGestureRecognizer *pan;
@property (strong, nonatomic) UIPinchGestureRecognizer *pinch;
@property (strong, nonatomic) UITapGestureRecognizer *doubleTap;
@property (strong, nonatomic) TouchGestureRecognizer *touch;

@property (nonatomic) MKCoordinateRegion originalRegion;
@property (strong, nonatomic) CLLocation *originalCenter;

@end

@implementation CenterLockingMapView

#pragma mark - UIView overrides
- (void)willMoveToSuperview:(UIView *)newSuperview {
    
    [super willMoveToSuperview:newSuperview];
    
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

/*
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
    [self setVisibleMapRect:boundingBox edgePadding:padding animated:animated];
}
 */

#pragma mark - UIGestureRecognizer handlers

/*
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
 */

- (void)handleDoubleTap:(UITapGestureRecognizer *)doubleTap {
    //NSLog(@"Double tap: %ld", doubleTap.state);
    
    if (doubleTap.state == UIGestureRecognizerStateEnded) {
        
        [self cancelScrollingUpdate];
        
        float zoomMultiplier = 0.5;
        MKCoordinateSpan currentSpan = self.region.span;
        MKCoordinateSpan zoomedSpan = MKCoordinateSpanMake(currentSpan.latitudeDelta * zoomMultiplier, currentSpan.longitudeDelta * zoomMultiplier);
        
        CLLocationCoordinate2D targetCenter;
        if (self.originalCenter) {
            targetCenter = self.originalCenter.coordinate;
        }
        else {
            targetCenter = self.centerCoordinate;
        }
        
        [self setRegion:MKCoordinateRegionMake(targetCenter, zoomedSpan) animated:YES];
    }
}

- (void)handlePinch:(UIPinchGestureRecognizer *)pinch {
    
    if (pinch.state == UIGestureRecognizerStateBegan) {
        //NSLog(@"pinch began");
        
        [self cancelScrollingUpdate];
        
        self.scrollEnabled = NO;
        
        if (!self.originalCenter) {
            CLLocationCoordinate2D centerCoordinate = self.centerCoordinate;
            self.originalCenter = [[CLLocation alloc] initWithLatitude:centerCoordinate.latitude longitude:centerCoordinate.longitude];
        }
        
        self.originalRegion = self.region;
    }
    else if (pinch.state == UIGestureRecognizerStateChanged) {
        //NSLog(@"pinch changed");
        
        double latdelta = self.originalRegion.span.latitudeDelta / pinch.scale;
        double londelta = self.originalRegion.span.longitudeDelta / pinch.scale;
        latdelta = MAX(MIN(latdelta, 150), 0);
        londelta = MAX(MIN(londelta, 150), 0);
        MKCoordinateSpan span = MKCoordinateSpanMake(latdelta, londelta);
        
        [self setRegion:MKCoordinateRegionMake(self.originalCenter.coordinate, span) animated:NO];
    }
    else if (pinch.state == UIGestureRecognizerStateCancelled) {
        //NSLog(@"pinch cancelled");
        self.scrollEnabled = YES;
    }
    else if (pinch.state == UIGestureRecognizerStateEnded) {
        //NSLog(@"pinch ended");
        self.scrollEnabled = YES;
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

#pragma mark - UIGestureRecognizerDelegate Methods
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    return YES;
}

#pragma mark - helper methods
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
    
    double latitudeDelta = self.region.span.latitudeDelta * (1 - pinchScale);
    double longitudeDelta = self.region.span.longitudeDelta * (1 - pinchScale);
    float minDelta = 0.003432;
    float maxDelta = 150;
    latitudeDelta = MAX(MIN(latitudeDelta, maxDelta), minDelta);
    longitudeDelta = MAX(MIN(longitudeDelta, maxDelta), minDelta);
    MKCoordinateSpan span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta);
    
    [self setRegion:MKCoordinateRegionMake(self.originalCenter.coordinate, span) animated:NO];
    
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

- (CGPoint)convertMapPointToPoint:(MKMapPoint)mapPoint {
    CLLocationCoordinate2D coordinate = MKCoordinateForMapPoint(mapPoint);
    return [self convertCoordinate:coordinate toPointToView:self];
}

- (void)lock {
    //[self removeGestureRecognizer:self.longPress];
    //[self removeGestureRecognizer:self.tap];
    
    [self addGestureRecognizer:self.touch];
    [self addGestureRecognizer:self.pinch];
    [self addGestureRecognizer:self.doubleTap];
    [self addGestureRecognizer:self.pan];
    
    self.zoomEnabled = NO;
}

- (void)unlock {
    //[self addGestureRecognizer:self.longPress];
    //[self addGestureRecognizer:self.tap];
    
    [self removeGestureRecognizer:self.pinch];
    [self removeGestureRecognizer:self.doubleTap];
    [self removeGestureRecognizer:self.touch];
    [self removeGestureRecognizer:self.pan];
    
    self.zoomEnabled = YES;
}

#pragma mark - Getters and Setters
- (void)setLockCenterWhileZooming:(BOOL)lockCenterWhileZooming {
    if (_lockCenterWhileZooming != lockCenterWhileZooming) {
        if (lockCenterWhileZooming) {
            [self lock];
        }
        else {
            [self unlock];
        }
    }
    
    _lockCenterWhileZooming = lockCenterWhileZooming;
}

- (CLLocationCoordinate2D)centerCoordinate {
    if (self.originalCenter) {
        return self.originalCenter.coordinate;
    }
    
    return [super centerCoordinate];
}

@end
