//
//  GoogleMapsTestMap.m
//  Bike Party
//
//  Created by Jon on 11/15/14.
//  Copyright (c) 2014 Modeo. All rights reserved.
//

#import <GoogleMaps/GoogleMaps.h>

#import "GoogleMapsTestMap.h"
#import "MFLocationManager.h"

@interface GoogleMapsTestMap ()

@property (weak, nonatomic) IBOutlet UIView *mapPlaceholderView;
@property (strong, nonatomic) MFLocationManager *locationManager;
@property (strong, nonatomic) GMSMapView *mapView;

@property (strong, nonatomic) UILongPressGestureRecognizer *longPress;

@end

@implementation GoogleMapsTestMap

- (void)viewDidLoad {
    
    //GMSCameraPosition *camera = [GMSCameraPosition cameraWithTarget:CLLocationCoordinate2DMake(0, 0) zoom:6];
    CGRect mapFrame = CGRectMake(0, 0, self.mapPlaceholderView.frame.size.width, self.mapPlaceholderView.frame.size.height);
    self.mapView = [GMSMapView mapWithFrame:mapFrame camera:nil];
    self.mapView.myLocationEnabled = YES;
    [self.mapPlaceholderView addSubview:self.mapView];
    
    self.locationManager = [MFLocationManager new];
    [self.locationManager findUserWithAccuracy:kCLLocationAccuracyHundredMeters andCallback:^(CLLocation *location, NSError *error) {
        if (!error) {
            
            [self showUser:location];
            //[self performSelector:@selector(showUser:) withObject:location afterDelay:1];
            
            // Creates a marker in the center of the map.
            /*
            GMSMarker *marker = [[GMSMarker alloc] init];
            marker.position = CLLocationCoordinate2DMake(-33.86, 151.20);
            marker.title = @"Sydney";
            marker.snippet = @"Australia";
            marker.map = mapView;
             */
            //marker.draggable = YES;
        }
    }];
    
}

- (void)showUser:(CLLocation *)location {
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithTarget:location.coordinate zoom:14];
    [self.mapView animateToCameraPosition:camera];
    //GMSCameraUpdate *camerUpadte = [GMSCameraUpdate zoomTo:camera.zoom];
    
    //[self.mapView animateWithCameraUpdate:camerUpadte];
    [self.mapView animateToCameraPosition:camera];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    
}

@end
