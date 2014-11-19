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
//@property (strong, nonatomic) UISwipeGestureRecognizer *swipe;
//@property (strong, nonatomic) NSArray *swipeGestures;
@property (nonatomic) MKCoordinateSpan previousZoomLevel;
//@property (strong, nonatomic) UIPanGestureRecognizer *pan;
//@property (strong, nonatomic) TouchGestureRecognizer *touch;
@property (strong, nonatomic) UIPinchGestureRecognizer *pinch;
@property (nonatomic) BOOL isAdjustingZoom;

@end

@implementation TestMapViewController

- (void)viewDidLoad {
    //[self.mapView addGestureRecognizer:self.longPress];
    
    //UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    //[self.mapView addGestureRecognizer:tap];
    
    //[self.mapView addGestureRecognizer:self.pan];
    
    //self.touch = [[TouchGestureRecognizer alloc] initWithTarget:self action:@selector(handleTouch:)];
    //self.touch.delegate = self;
    
    self.longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    self.longPress.delegate = self;
    [self.mapView addGestureRecognizer:self.longPress];
    
    self.pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    self.pinch.delegate = self;
}

- (void)handlePinch:(UIPinchGestureRecognizer *)pinch {
    
    static MKCoordinateRegion originalRegion;
    
    if (pinch.state == UIGestureRecognizerStatePossible) {
        NSLog(@"pinch possible");
    }
    else if (pinch.state == UIGestureRecognizerStateBegan) {
        NSLog(@"pinch began");
        self.mapView.scrollEnabled = NO;
        self.mapView.zoomEnabled = NO;
        
        originalRegion = self.mapView.region;
    }
    else if (pinch.state == UIGestureRecognizerStateChanged) {
        NSLog(@"pinch changed");
        
        double latdelta = originalRegion.span.latitudeDelta / pinch.scale;
        double londelta = originalRegion.span.longitudeDelta / pinch.scale;
        
        // TODO: set these constants to appropriate values to set max/min zoomscale
        latdelta = MAX(MIN(latdelta, 150), 0);
        londelta = MAX(MIN(londelta, 150), 0);
        MKCoordinateSpan span = MKCoordinateSpanMake(latdelta, londelta);
        
        [self.mapView setRegion:MKCoordinateRegionMake(originalRegion.center, span) animated:NO];
    }
    else if (pinch.state == UIGestureRecognizerStateCancelled) {
        NSLog(@"pinch cancelled");
    }
    else if (pinch.state == UIGestureRecognizerStateEnded) {
        NSLog(@"pinch ended");
        self.mapView.scrollEnabled = YES;
        self.mapView.zoomEnabled = YES;
    }
}

- (void)handleTouch:(TouchGestureRecognizer *)touch {
    
    if (touch.state == UIGestureRecognizerStateBegan) {
        NSLog(@"Started Touching");
        MKCoordinateSpan span = MKCoordinateSpanMake(0.008297, 0.006666);
        MKCoordinateRegion region = MKCoordinateRegionMake(self.mapView.centerCoordinate, span);
        [self.mapView setRegion:region animated:YES];
    }
    else if (touch.state == UIGestureRecognizerStateEnded) {
        NSLog(@"Ended Touching");
        MKCoordinateSpan span = self.previousZoomLevel;
        MKCoordinateRegion region = MKCoordinateRegionMake(self.mapView.centerCoordinate, span);
        [self.mapView setRegion:region animated:YES];
    }
}

- (void)handleTap:(UITapGestureRecognizer *)tap {
    NSLog(@"handle tap: %ld", tap.state);
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
        
        MKCoordinateSpan span = MKCoordinateSpanMake(0.008297, 0.006666);
        MKCoordinateRegion region = MKCoordinateRegionMake(locationOnMap, span);
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
        
        self.previousZoomLevel = self.mapView.region.span;
    }
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)swipe {
    NSLog(@"Swipe");
    
    [self.mapView setRegion:MKCoordinateRegionMake(self.mapView.centerCoordinate, self.previousZoomLevel) animated:YES];
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    CGPoint velocity = [pan velocityInView:self.mapView];
    NSLog(@"pan velocity: %f", velocity.x + velocity.y);
    
    /*
    if (ABS(velocity.x + velocity.y) > 1000 && !self.isAdjustingZoom) {
        self.isAdjustingZoom = YES;
        [self.mapView setRegion:MKCoordinateRegionMake(self.mapView.centerCoordinate, self.previousZoomLevel) animated:YES];
    }
     */
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    MKPointAnnotation *annotation = [MKPointAnnotation new];
    annotation.coordinate = self.mapView.centerCoordinate;
    annotation.title = @"testicle";
    //[self.mapView addAnnotation:annotation];
    self.isAdjustingZoom = NO;
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    
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

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    //NSLog(@"shouldBeRequiredToFail");
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    //NSLog(@"shouldReceiveTouch");
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    //NSLog(@"shouldRecognizeSimultaneouslyWithGestureRecognizer");
    
    if ([otherGestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]]) {
        //NSLog(@"Is Pinch!");
        return YES;
    }
    else if ([otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        NSLog(@"Is pan!");
    }
    
    if ([gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        return NO;
    }
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    //NSLog(@"shouldRequireFailureOfGestureRecognizer");
    return NO;
}
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    //NSLog(@"gestureRecognizerShouldBegin");
    return YES;
}
@end
