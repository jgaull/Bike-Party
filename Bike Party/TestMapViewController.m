//
//  TestMapViewController.m
//  Bike Party
//
//  Created by Jon on 11/15/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import "TestMapViewController.h"
#import "TouchGestureRecognizer.h"

@interface TestMapViewController ()

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UINavigationBar *navBar;

@property (weak, nonatomic) MKPinAnnotationView *pinView;

@property (strong, nonatomic) UILongPressGestureRecognizer *longPress;
@property (strong, nonatomic) UIPanGestureRecognizer *pan;
@property (strong, nonatomic) UIPinchGestureRecognizer *pinch;

@property (nonatomic) MKCoordinateRegion originalRegion;
@property (strong, nonatomic) CLLocation *originalCenter;

@end

@implementation TestMapViewController

- (void)viewDidLoad {
    self.longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [self.mapView addGestureRecognizer:self.longPress];
    
    self.pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    self.pinch.delegate = self;
    self.pinch.cancelsTouchesInView = YES;
    
    self.pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    self.pan.maximumNumberOfTouches = 1;
    self.pan.delegate = self;
    [self.mapView addGestureRecognizer:self.pan];
}

- (void)handlePinch:(UIPinchGestureRecognizer *)pinch {
    
    //static MKCoordinateRegion originalRegion;
    
    if (pinch.state == UIGestureRecognizerStatePossible) {
        //NSLog(@"pinch possible");
    }
    else if (pinch.state == UIGestureRecognizerStateBegan) {
        //NSLog(@"pinch began");
        self.mapView.scrollEnabled = NO;
        self.mapView.zoomEnabled = NO;
        
        /*
        CGPoint oldPointInView = [self.mapView convertCoordinate:self.originalCenter.coordinate toPointToView:self.mapView];
        CGPoint newPointInView = self.mapView.center;
        CGFloat distance = hypotf(newPointInView.x - oldPointInView.x, newPointInView.y - oldPointInView.y);
        
        if (distance < 150 && self.originalCenter) {
            NSLog(@"reset from pan");
            self.mapView.centerCoordinate = self.originalCenter.coordinate;
        }
         */
        
        if (!self.originalCenter) {
            CLLocationCoordinate2D centerCoordinate = self.mapView.centerCoordinate;
            self.originalCenter = [[CLLocation alloc] initWithLatitude:centerCoordinate.latitude longitude:centerCoordinate.longitude];
        }
        
        self.originalRegion = self.mapView.region;
        
        //NSLog(@"old center: %f, %f", self.originalCenter.coordinate.latitude, self.originalCenter.coordinate.longitude);
    }
    else if (pinch.state == UIGestureRecognizerStateChanged) {
        //NSLog(@"pinch changed");
        
        double latdelta = self.originalRegion.span.latitudeDelta / pinch.scale;
        double londelta = self.originalRegion.span.longitudeDelta / pinch.scale;
        
        // TODO: set these constants to appropriate values to set max/min zoomscale
        latdelta = MAX(MIN(latdelta, 150), 0);
        londelta = MAX(MIN(londelta, 150), 0);
        MKCoordinateSpan span = MKCoordinateSpanMake(latdelta, londelta);
        
        [self.mapView setRegion:MKCoordinateRegionMake(self.originalCenter.coordinate, span) animated:NO];
    }
    else if (pinch.state == UIGestureRecognizerStateCancelled) {
        //NSLog(@"pinch cancelled");
    }
    else if (pinch.state == UIGestureRecognizerStateEnded) {
        //NSLog(@"pinch ended");
        self.mapView.scrollEnabled = YES;
        self.mapView.zoomEnabled = YES;
        
        //NSLog(@"new center: %f, %f", self.mapView.centerCoordinate.latitude, self.mapView.centerCoordinate.longitude);
        
        //self.originalCenter = nil;
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)longPress {
    if (longPress.state == UIGestureRecognizerStateBegan) {
        NSLog(@"Long pressed");
        CGPoint touchPoint = [longPress locationInView:self.mapView];
        CLLocationCoordinate2D locationOnMap = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
        
        MKPointAnnotation *annotation = [MKPointAnnotation new];
        annotation.coordinate = locationOnMap;
        annotation.title = @"testicle";
        //[self.mapView addAnnotation:annotation];
        
        //MKCoordinateSpan span = MKCoordinateSpanMake(0.008297, 0.006666);
        //MKCoordinateRegion region = MKCoordinateRegionMake(locationOnMap, span);
        //[self.mapView setRegion:region animated:YES];
        
        MKPinAnnotationView *mapPin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"testPin"];
        
        CGSize pinSize = mapPin.frame.size;
        CGSize frameSize = self.mapView.frame.size;
        CGPoint offset = mapPin.centerOffset;
        
        mapPin.frame = CGRectMake(frameSize.width / 2 - offset.x, frameSize.height / 2 - pinSize.height - offset.y - 10, pinSize.width, pinSize.height);
        [self.mapView addSubview:mapPin];
        
        self.pinView = mapPin;
        
        [self.mapView removeGestureRecognizer:self.longPress];
        //[self.mapView addGestureRecognizer:self.touch];
        [self.mapView addGestureRecognizer:self.pinch];
        //[self.mapView addGestureRecognizer:self.pan];
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    
    if (pan.state == UIGestureRecognizerStatePossible) {
        NSLog(@"pan possible");
    }
    else if (pan.state == UIGestureRecognizerStateBegan) {
        NSLog(@"pan began");
        self.originalCenter = nil;
    }
    else if (pan.state == UIGestureRecognizerStateChanged) {
        //NSLog(@"num touches = %lu", (unsigned long)pan.numberOfTouches);
    }
    else if (pan.state == UIGestureRecognizerStateCancelled) {
        NSLog(@"pan cancelled");
    }
    else if (pan.state == UIGestureRecognizerStateEnded) {
        NSLog(@"pan ended");
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
        //pin.draggable = YES;
        
    } else {
        pin.annotation = annotation;
    }
    
    return pin;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    return YES;
}

@end
